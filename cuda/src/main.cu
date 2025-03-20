#include <iostream>
#include <fstream>
#include <math.h>
#include <float.h>
#include "vec3.cuh"
#include "ray.cuh"
#include "sphere.cuh"
#include "plane.cuh"
#include "scene.cuh"
#include "material.cuh"
#include "camera.cuh"
#include <curand_kernel.h>

#define checkCudaErrors(val) check_cuda((val), #val, __FILE__, __LINE__)
void check_cuda(cudaError_t result, char const *const func, const char *const file, int const line)
{
    if (result)
    {
        std::cerr << "CUDA error = " << static_cast<unsigned int>(result) << " at " << file << ":" << line << " '" << func << "' \n";
        cudaDeviceReset();
        exit(99);
    }
}

void writeImage(color *fb, int width, int height)
{
    std::ofstream out("image.ppm");
    out << "P3\n"
        << width << " " << height << "\n255\n";

    for (int j = 0; j < width * height; ++j)
    {
        out << static_cast<int>(255.999f * std::sqrt(fb[j].r())) << ' '
            << static_cast<int>(255.999f * std::sqrt(fb[j].g())) << ' '
            << static_cast<int>(255.999f * std::sqrt(fb[j].b())) << '\n';
    }
    out.close();
}

__device__ color ray_color(const ray &r, hitable *world, int depth, curandState *local_rand_state)
{
    ray cur_ray = r;
    color cur_attenuation(1.0f, 1.0f, 1.0f);

    for (int i = 0; i < depth; i++)
    {
        hit_record rec;
        if (world->hit(cur_ray, 0.001f, FLT_MAX, rec))
        {
            ray scattered;
            color attenuation;
            if (rec.mat_ptr->scatter(cur_ray, rec.normal, rec.p, attenuation, scattered, local_rand_state))
            {
                cur_attenuation = cur_attenuation * attenuation;
                cur_ray = scattered;
            }
            else
            {
                return color(0.0f, 0.0f, 0.0f);
            }
        }
        else
        {
            vec3 unit_direction = cur_ray.dir.normalized();
            float t = 0.5f * (unit_direction.y() + 1.0f);
            color c = (1.0f - t) * color(1.0f, 1.0f, 1.0f) + t * color(0.5f, 0.7f, 1.0f);
            return cur_attenuation * c;
        }
    }

    return color(0.0f, 0.0f, 0.0f);
}

__global__ void rand_init(curandState *rand_state, int width, int height)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int j = threadIdx.y + blockIdx.y * blockDim.y;
    if ((i >= width) || (j >= height))
        return;

    int pixel_index = j * width + i;
    curand_init(1984, pixel_index, 0, &rand_state[pixel_index]);
}

__global__ void create_scene(hitable **list, hitable **world, camera **cam, int width, int height)
{
    if (threadIdx.x == 0 && blockIdx.x == 0)
    {
        material *plane_mat = new material(color(0.5f, 0.5f, 0.5f), 1.0f);
        material *m1 = new material(color(0.1f, 0.2f, 0.5f), 1.0f);
        material *m2 = new material(color(0.01f, 0.01f, 0.01f), 0.05f);
        material *m3 = new material(color(1.0f, 1.0f, 1.0f), 0.0f);

        list[0] = new sphere(point3(-1.0f, 0.5f, -1.0f), 0.5f, m1);
        list[1] = new sphere(point3(0.0f, 0.5f, -1.5f), 0.5f, m3);
        list[2] = new sphere(point3(1.0f, 0.5f, -1.0f), 0.5f, m2);
        list[3] = new plane(point3(0.0f, 0.0f, 0.0f), vec3(0.0f, 1.0f, 0.0f), plane_mat);

        *world = new scene(list, 4);
        *cam = new camera(width, height);
    }
}

__global__ void render(color *fb, int width, int height, int samples, int max_depth,
                       curandState *rand_state, hitable **world, camera **cam)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int j = threadIdx.y + blockIdx.y * blockDim.y;
    if ((i >= width) || (j >= height))
        return;

    int pixel_index = j * width + i;
    curandState local_rand_state = rand_state[pixel_index];
    color pixel_color(0.0f, 0.0f, 0.0f);

    for (int s = 0; s < samples; s++)
    {
        float u = float(i + curand_uniform(&local_rand_state)) / float(width - 1);
        float v = (height - 1 - j + curand_uniform(&local_rand_state)) / float(height - 1);
        ray r = (*cam)->get_ray(u, v);
        pixel_color += ray_color(r, *world, max_depth, &local_rand_state);
    }

    pixel_color /= float(samples);
    fb[pixel_index] = pixel_color;
}

int main(void)
{
    int dev;
    checkCudaErrors(cudaGetDevice(&dev));
    cudaDeviceProp deviceProp;
    checkCudaErrors(cudaGetDeviceProperties(&deviceProp, dev));
    std::cout << "Running on GPU: " << deviceProp.name << std::endl;

    int nx = 1920;
    int ny = 1080;
    int tx = 8;
    int ty = 8;
    int samples_per_pixel = 500;
    int max_depth = 10;

    int num_pixels = nx * ny;
    size_t fb_size = num_pixels * sizeof(vec3);

    vec3 *fb;
    checkCudaErrors(cudaMallocManaged((void **)&fb, fb_size));

    // Allocate random state
    curandState *d_rand_state;
    checkCudaErrors(cudaMallocManaged((void **)&d_rand_state, num_pixels * sizeof(curandState)));

    // Allocate scene objects and world
    hitable **d_list;
    checkCudaErrors(cudaMallocManaged((void **)&d_list, 4 * sizeof(hitable *)));
    hitable **d_world;
    checkCudaErrors(cudaMallocManaged((void **)&d_world, sizeof(hitable *)));
    camera **d_camera;
    checkCudaErrors(cudaMallocManaged((void **)&d_camera, sizeof(camera *)));

    // Initialize CUDA random state
    dim3 blocks(nx / tx + 1, ny / ty + 1);
    dim3 threads(tx, ty);
    rand_init<<<blocks, threads>>>(d_rand_state, nx, ny);
    checkCudaErrors(cudaGetLastError());
    checkCudaErrors(cudaDeviceSynchronize());

    // Create world
    create_scene<<<1, 1>>>(d_list, d_world, d_camera, nx, ny);
    checkCudaErrors(cudaGetLastError());
    checkCudaErrors(cudaDeviceSynchronize());

    // Setup CUDA events to measure render time
    cudaEvent_t start, stop;
    checkCudaErrors(cudaEventCreate(&start));
    checkCudaErrors(cudaEventCreate(&stop));

    checkCudaErrors(cudaEventRecord(start));
    // Render scene
    render<<<blocks, threads>>>(fb, nx, ny, samples_per_pixel, max_depth, d_rand_state, d_world, d_camera);
    checkCudaErrors(cudaGetLastError());
    checkCudaErrors(cudaEventRecord(stop));
    checkCudaErrors(cudaEventSynchronize(stop));

    float milliseconds = 0;
    checkCudaErrors(cudaEventElapsedTime(&milliseconds, start, stop));
    std::cout << "Render time: " << milliseconds << " ms." << std::endl;

    checkCudaErrors(cudaEventDestroy(start));
    checkCudaErrors(cudaEventDestroy(stop));

    // Write image to file
    std::cout << "Rendering complete, writing image to file..." << std::endl;
    writeImage(fb, nx, ny);
    std::cout << "Image saved." << std::endl;

    // Cleanup
    checkCudaErrors(cudaFree(d_camera));
    checkCudaErrors(cudaFree(d_world));
    checkCudaErrors(cudaFree(d_list));
    checkCudaErrors(cudaFree(d_rand_state));
    checkCudaErrors(cudaFree(fb));

    return 0;
}
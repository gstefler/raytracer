#pragma once
#include "hittable.h"
#include "camera.h"
#include <vector>
#include <atomic>
#include <memory>
#include <omp.h>
#include <random>
#include <thread>
#include <chrono>
#include <iostream>

struct scene : public hittable
{
    std::vector<std::shared_ptr<hittable>> objects;
    const camera cam;
    const int width, height, max_depth, samples_per_pixel;
    std::atomic<int> pixels_done = 0;

    scene() = default;
    scene(int width, int height, int max_depth, int samples_per_pixel) : cam(width, height), width(width), height(height), max_depth(max_depth), samples_per_pixel(samples_per_pixel) {}

    void add(std::shared_ptr<hittable> object)
    {
        objects.push_back(object);
    }

    virtual bool hit(const ray &r, float t_min, float t_max, hit_record &rec) const override
    {
        hit_record temp_rec;
        bool hit_anything = false;
        float closest_so_far = t_max;
        for (const auto &object : objects)
        {
            if (object->hit(r, t_min, closest_so_far, temp_rec))
            {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }
        return hit_anything;
    }

    color ray_color(const ray &r, int depth) const
    {
        if (depth <= 0)
            return {0, 0, 0};

        hit_record rec;
        if (hit(r, 0.001f, std::numeric_limits<float>::infinity(), rec))
        {
            ray scattered;
            color attenuation;
            if (rec.mat_ptr->scatter(r, rec.normal, rec.p, attenuation, scattered))
                return attenuation * ray_color(scattered, depth - 1);
            return {0, 0, 0};
        }
        vector3 unit_direction = r.direction.normalized();
        float t = 0.5f * (unit_direction.y + 1.0f);
        return mix({1.0f, 1.0f, 1.0f}, {0.5f, 0.7f, 1.0f}, t);
    }

    std::vector<color> render() noexcept
    {
        std::vector<color> pixels(width * height);

        std::thread progress_thread([&]()
                                    {
            while (pixels_done < width * height)
            {
                std::this_thread::sleep_for(std::chrono::milliseconds(500));
                float progress = (static_cast<float>(pixels_done) / (width * height)) * 100.0f;
                std::cerr << "\rProgress: " << progress << "%" << std::flush;
            } });
        
        std::cout << "rendering with " << omp_get_max_threads() << " threads\n";
        auto render_start = std::chrono::high_resolution_clock::now();

#pragma omp parallel for schedule(static)
        for (int j = 0; j < height; ++j)
        {
            std::mt19937 local_generator(42 + omp_get_thread_num());
            std::uniform_real_distribution<float> local_distribution(0.0, 1.0);
            auto local_random_float = [&local_generator, &local_distribution]()
            { return local_distribution(local_generator); };

            for (int i = 0; i < width; ++i)
            {
                vector3 pixel_color(0, 0, 0);
                for (int s = 0; s < samples_per_pixel; ++s)
                {
                    float u = (i + local_random_float()) / (width - 1);
                    float v = ((height - 1 - j) + local_random_float()) / (height - 1);
                    ray r = cam.get_ray(u, v);
                    pixel_color = pixel_color + ray_color(r, max_depth);
                }
                pixel_color = pixel_color / float(samples_per_pixel); // average color
                int index = j * width + i;
                pixels[index] = pixel_color;
                pixels_done++;
            }
        }
        progress_thread.join();
        auto render_end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double> render_time = render_end - render_start;
        std::cerr << "\nRender time: " << render_time.count() << " seconds.\n";
        return pixels;
    }
};

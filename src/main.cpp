#include <iostream>
#include <fstream>
#include <omp.h>
#include "scene.h"
#include "sphere.h"
#include "plane.h"
#include "material.h"

void write_image(const std::vector<color> &pixels, int image_width, int image_height)
{
    std::ofstream out("image.ppm");
    out << "P3\n"
        << image_width << " " << image_height << "\n255\n";
    for (const auto &pixel_color : pixels)
    {
        int ir = static_cast<int>(255.999 * std::sqrt(pixel_color.x));
        int ig = static_cast<int>(255.999 * std::sqrt(pixel_color.y));
        int ib = static_cast<int>(255.999 * std::sqrt(pixel_color.z));
        out << ir << " " << ig << " " << ib << "\n";
    }
    out.close();
}

int main()
{
    const int image_width = 1920;
    const int image_height = 1080;
    const int max_depth = 5;
    const int samples_per_pixel = 1000;

    scene world(image_width, image_height, max_depth, samples_per_pixel);

    material plane_mat({0.5f, 0.5f, 0.5f});
    material m1({0.1f, 0.2f, 0.5f}, 1.0f);
    material m2({0.01f, 0.01f, 0.01f}, 0.05f);
    material m3({1.0f, 1.0f, 1.0f}, 0.0f);

    sphere s1({-1.0f, 0.5f, -1.0f}, 0.5f, m1);
    sphere s2({0.0f, 0.5f, -1.5f}, 0.5f, m3);
    sphere s3({1.0f, 0.5f, -1.0f}, 0.5f, m2);
    plane p({0, 0, 0}, {0, 1, 0}, plane_mat);

    world.add(std::make_shared<sphere>(s1));
    world.add(std::make_shared<sphere>(s2));
    world.add(std::make_shared<sphere>(s3));
    world.add(std::make_shared<plane>(p));

    omp_set_num_threads(12);
    const auto pixels = world.render();

    write_image(pixels, image_width, image_height);

    std::cerr << "Done.\n";
    return 0;
}

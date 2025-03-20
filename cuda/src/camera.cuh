#pragma once

#include "vec3.cuh"
#include "ray.cuh"

struct camera {
    point3 origin;
    point3 lower_left_corner;
    vec3 horizontal, vertical;

    __device__ camera()
    {
        float viewport_height = 2.0f;
        float aspect_ratio = 1270.0f / 720.0f;
        float viewport_width = aspect_ratio * viewport_height;

        origin = {0.0f, 1.0f, 3.0f};
        horizontal = {viewport_width, 0.0f, 0.0f};
        vertical = {0.0f, viewport_height, 0.0f};

        lower_left_corner = origin - (horizontal * 0.5f) - (vertical * 0.5f) - vec3{0.0f, 0.0f, 2.0f};
    }

    __device__ camera(int width, int height) {
        float viewport_height = 2.0f;
        float aspect_ratio = static_cast<float>(width) / static_cast<float>(height);
        float viewport_width = aspect_ratio * viewport_height;

        origin = {0.0f, 1.2f, 4.0f};
        horizontal = {viewport_width, 0.0f, 0.0f};
        vertical = {0.0f, viewport_height, 0.0f};

        lower_left_corner = origin - (horizontal * 0.5f) - (vertical * 0.5f) - vec3{0.0f, 0.0f, 3.0f};
    }

    __device__ ray get_ray(float u, float v) const
    {
        return ray(origin, lower_left_corner + horizontal * u + vertical * v - origin);
    }
};

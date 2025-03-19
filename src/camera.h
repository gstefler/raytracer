#pragma once
#include "ray.h"

struct camera {
    point3 origin;
    point3 lower_left_corner;
    vector3 horizontal, vertical;

    camera()
    {
        float viewport_height = 2.0f;
        float aspect_ratio = 1270.0f / 720.0f; // update as needed
        float viewport_width = aspect_ratio * viewport_height;

        origin = {0.0, 1.0, 3.0};
        horizontal = {viewport_width, 0.0, 0.0};
        vertical = {0.0, viewport_height, 0.0};

        lower_left_corner = origin - (horizontal * 0.5f) - (vertical * 0.5f) - vector3{0.0, 0.0, 2.0};
    }

    camera(int width, int height) {
        float viewport_height = 2.0f;
        float aspect_ratio = static_cast<float>(width) / static_cast<float>(height);
        float viewport_width = aspect_ratio * viewport_height;

        origin = {0.0f, 1.2f, 4.0f};
        horizontal = {viewport_width, 0.0, 0.0};
        vertical = {0.0, viewport_height, 0.0};

        lower_left_corner = origin - (horizontal * 0.5f) - (vertical * 0.5f) - vector3{0.0, 0.0, 3.0f};
    }

    ray get_ray(float u, float v) const
    {
        return ray(origin, lower_left_corner + horizontal * u + vertical * v - origin);
    }
};
#pragma once
#include "vec3.cuh"

struct ray
{
    point3 orig;
    vec3 dir;

    __device__ ray() {}
    __device__ ray(const point3 &origin, const vec3 &direction) : orig(origin), dir(direction) {}

    __device__ vec3 at(float t) const
    {
        return orig + t * dir;
    }
};

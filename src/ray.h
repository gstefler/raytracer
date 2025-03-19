#pragma once
#include "vector3.h"

struct ray
{
    point3 origin;
    vector3 direction;

    ray() = default;
    ray(const point3 &origin, const vector3 &direction) : origin(origin), direction(direction) {}

    point3 at(float t) const { return origin + direction * t; }
};

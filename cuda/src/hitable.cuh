#pragma once

#include "ray.cuh"
#include "material.cuh"

struct hit_record
{
    point3 p;
    vec3 normal;
    float t;
    bool front_face;
    material *mat_ptr;

    __device__ inline void set_face_normal(const ray &r, const vec3 &outward_normal)
    {
        front_face = dot(r.dir, outward_normal) < 0.f;
        normal = front_face ? outward_normal : -outward_normal;
    }
};

struct hitable
{
    __device__ virtual bool hit(const ray &r, float t_min, float t_max, hit_record &rec) const = 0;
};

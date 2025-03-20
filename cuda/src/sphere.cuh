#pragma once
#include "hitable.cuh"
#include "ray.cuh"

struct sphere : public hitable
{
    point3 center;
    float radius;
    material *mat_ptr;

    __device__ sphere() {}
    __device__ sphere(point3 cen, float r, material *m) : center(cen), radius(r), mat_ptr(m) {}

    __device__ virtual bool hit(const ray &r, float t_min, float t_max, hit_record &rec) const
    {
        vec3 oc = r.orig - center;
        float a = r.dir.squared_length();
        float half_b = dot(oc, r.dir);
        float c = oc.squared_length() - radius * radius;
        float discriminant = half_b * half_b - a * c;

        if (discriminant < 0.f)
            return false;

        float sqrtd = sqrtf(discriminant);
        float root = (-half_b - sqrtd) / a;

        if(root < t_min || root > t_max) {
            root = (-half_b + sqrtd) / a;
            if(root < t_min || root > t_max)
                return false;
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        vec3 outward_normal = (rec.p - center) / radius;
        rec.set_face_normal(r, outward_normal);
        rec.mat_ptr = mat_ptr;
        return true;
    }
};
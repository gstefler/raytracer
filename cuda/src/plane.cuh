#pragma once

#include "hitable.cuh"
#include "ray.cuh"

struct plane : public hitable
{
    point3 center;
    vec3 normal;
    material *mat_ptr;

    __device__ plane() {}
    __device__ plane(point3 cen, vec3 n, material *m) : center(cen), normal(n.normalized()), mat_ptr(m) {}

    __device__ virtual bool hit(const ray &r, float t_min, float t_max, hit_record &rec) const override
    {
        float denom = dot(r.dir, normal);
        
        // If the ray is parallel to the plane
        if (fabs(denom) < 0.0001f) 
            return false;
            
        float t = dot(center - r.orig, normal) / denom;
        
        if (t < t_min || t > t_max)
            return false;
            
        rec.t = t;
        rec.p = r.at(t);
        rec.set_face_normal(r, normal);
        rec.mat_ptr = mat_ptr;
        
        return true;
    }
};

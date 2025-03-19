#pragma once
#include "ray.h"
#include "material.h"

struct hit_record {
    point3 p;
    vector3 normal;
    float t;
    bool front_face;
    material* mat_ptr;

    inline void set_face_normal(const ray& r, const vector3& outward_normal) {
        front_face = vector3::dot(r.direction, outward_normal) < 0;
        normal = front_face ? outward_normal : outward_normal * -1;
    }
};

struct hittable {
    virtual bool hit(const ray& r, float t_min, float t_max, hit_record &rec) const = 0;
};

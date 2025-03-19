#pragma once
#include "hittable.h"

struct plane : public hittable {
    point3 point;
    vector3 normal;
    material mat;

    plane() = default;
    plane(point3 p, vector3 n, material m) : point(p), normal(n.normalized()), mat(m) {}

    virtual bool hit(const ray& r, float t_min, float t_max, hit_record &rec) const override {
        float denom = vector3::dot(normal, r.direction);
        if (std::fabs(denom) < 1e-6)
            return false;
        float t = vector3::dot(point - r.origin, normal) / denom;
        if(t < t_min || t > t_max)
            return false;
        rec.t = t;
        rec.p = r.at(t);
        rec.set_face_normal(r, normal);
        rec.mat_ptr = const_cast<material*>(&mat);
        return true;
    }
};

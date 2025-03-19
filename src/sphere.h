#pragma once
#include "hittable.h"
#include <cmath>

struct sphere : public hittable {
    point3 center;
    float radius;
    material mat;

    sphere() = default;
    sphere(point3 cen, float r, material m) : center(cen), radius(r), mat(m) {}

    virtual bool hit(const ray& r, float t_min, float t_max, hit_record &rec) const override {
        vector3 oc = r.origin - center;
        float a = r.direction.squared_length();
        float half_b = vector3::dot(oc, r.direction);
        float c = oc.squared_length() - radius * radius;
        float discriminant = half_b * half_b - a * c;
        if(discriminant < 0)
            return false;
        float sqrtd = std::sqrt(discriminant);

        float root = (-half_b - sqrtd) / a;
        if(root < t_min || root > t_max) {
            root = (-half_b + sqrtd) / a;
            if(root < t_min || root > t_max)
                return false;
        }
        
        rec.t = root;
        rec.p = r.at(rec.t);
        vector3 outward_normal = (rec.p - center) / radius;
        rec.set_face_normal(r, outward_normal);
        rec.mat_ptr = const_cast<material*>(&mat);
        return true;
    }
};

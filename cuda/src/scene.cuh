#pragma once

#include "hitable.cuh"

struct scene : public hitable {
    hitable **list;
    int list_size;

    __device__ scene() {}
    __device__ scene(hitable **l, int n) : list(l), list_size(n) {}

    __device__ virtual bool hit(const ray &r, float t_min, float t_max, hit_record &rec) const override {
        hit_record temp_rec;
        bool hit_anything = false;
        float closest_so_far = t_max;

        for (int i = 0; i < list_size; i++) {
            if (list[i]->hit(r, t_min, closest_so_far, temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }

        return hit_anything;
    }
};
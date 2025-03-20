#pragma once
#include "vec3.cuh"
#include "ray.cuh"
#include <curand_kernel.h>

__device__ inline vec3 reflect(const vec3 &v, const vec3 &n)
{
    return v - n * 2 * dot(v, n);
}

__device__ vec3 refract(const vec3 &v, const vec3 &n, float ni_over_nt)
{
    const vec3 uv = v.normalized();
    const float dt = dot(uv, n);
    const float discriminant = 1.f - ni_over_nt * ni_over_nt * (1.f - dt * dt);
    if (discriminant > 0.f)
    {
        return (uv - n * dt) * ni_over_nt - n * sqrtf(discriminant);
    }
    return reflect(v, n);
}

#define RANDVEC3 vec3(curand_uniform(local_rand_state), curand_uniform(local_rand_state), curand_uniform(local_rand_state))
__device__ vec3 random_in_unit_sphere(curandState *local_rand_state)
{
    vec3 p;
    do
    {
        p = 2.f * RANDVEC3 - vec3(1.f, 1.f, 1.f);
    } while (p.squared_length() >= 1.f);
    return p;
}

struct material
{
    color albedo = {1.f, 1.f, 1.f};
    float roughness = 1.f;

    __device__ material() {}
    __device__ material(const color &a, float f) : albedo(a), roughness(f) {}

    __device__ bool scatter(const ray& r_in, const vec3& normal, point3& hit_point, color& attenuation, ray& scattered, curandState *local_rand_state) const
    {
        vec3 reflected = reflect(r_in.dir.normalized(), normal);
        vec3 scatter_direction;

        if (roughness <= 0.f)
            scatter_direction = reflected;
        else if (roughness >= 1.f) {
            scatter_direction = normal + random_in_unit_sphere(local_rand_state);
            if (scatter_direction.squared_length() < 0.001f)
                scatter_direction = normal;
        } else {
            vec3 diffuse_direction = normal + random_in_unit_sphere(local_rand_state);
            if (diffuse_direction.squared_length() < 0.001f)
                diffuse_direction = normal;
            
            // Fix the intermediate case by interpolating between reflection and diffuse
            scatter_direction = reflected * (1.0f - roughness) + diffuse_direction * roughness;
        }

        scattered = ray(hit_point, scatter_direction);
        attenuation = albedo;
        return true;
    }
};

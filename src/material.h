#pragma once
#include "ray.h"
#include <random>

inline vector3 thread_safe_random_unit_vector() {
    static thread_local std::random_device rd;
    static thread_local std::mt19937 gen(rd());
    static thread_local std::uniform_real_distribution<float> dis(0.0f, 1.0f);
    float z = dis(gen) * 2.0f - 1.0f;
    float a = dis(gen) * 2.0f * 3.14159265359f;
    float r = std::sqrt(1.0f - z * z);
    float x = r * std::cos(a);
    float y = r * std::sin(a);
    return vector3(x, y, z);
}

struct material
{
    color albedo = {1.0f, 1.0f, 1.0f};
    float roughness = 1.0f;
    
    material() = default;
    material(const color& a, float r = 1.0f) : albedo(a), roughness(r) {}
    
    bool scatter(const ray& r_in, const vector3& normal, point3& hit_point, color& attenuation, ray& scattered) const {
        vector3 reflected = vector3::reflect(r_in.direction.normalized(), normal);
        
        vector3 scatter_direction;
        
        if (roughness <= 0.0f) {
            scatter_direction = reflected;
        } 
        else if (roughness >= 1.0f) {
            scatter_direction = normal + thread_safe_random_unit_vector();
            if (scatter_direction.squared_length() < 0.001f)
                scatter_direction = normal;
        }
        else {
            vector3 diffuse_dir = normal + thread_safe_random_unit_vector();
            if (diffuse_dir.squared_length() < 0.001f)
                diffuse_dir = normal;
            scatter_direction = mix(reflected, diffuse_dir, roughness).normalized();
        }
        
        scattered = ray(hit_point, scatter_direction);
        attenuation = albedo;
        
        return true;
    }
};

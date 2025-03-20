#pragma once
#include <cmath>
#include <random>

struct vector3
{
    float x, y, z;

    vector3() : x(0), y(0), z(0) {}
    vector3(const float x, const float y, const float z) : x(x), y(y), z(z) {}

    inline vector3 operator+(const vector3 &v) const { return {x + v.x, y + v.y, z + v.z}; }
    inline vector3 operator-(const vector3 &v) const { return {x - v.x, y - v.y, z - v.z}; }
    inline vector3 operator*(const float t) const { return {x * t, y * t, z * t}; }
    inline vector3 operator/(const float t) const { return {x / t, y / t, z / t}; }

    inline vector3 operator*(const vector3 &v) const { return {x * v.x, y * v.y, z * v.z}; }

    inline float length() const { return std::sqrt(x * x + y * y + z * z); }
    inline float squared_length() const { return x * x + y * y + z * z; }

    inline void normalize()
    {
        const float k = 1.0f / length();
        x *= k;
        y *= k;
        z *= k;
    }

    inline vector3 normalized() const
    {
        const float k = 1.0f / length();
        return {x * k, y * k, z * k};
    }

    static float dot(const vector3 &v1, const vector3 &v2)
    {
        return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
    }

    static vector3 cross(const vector3 &v1, const vector3 &v2)
    {
        return {
            v1.y * v2.z - v1.z * v2.y,
            v1.z * v2.x - v1.x * v2.z,
            v1.x * v2.y - v1.y * v2.x};
    }

    static vector3 reflect(const vector3 &v, const vector3 &n)
    {
        return v - n * 2 * dot(v, n);
    }

    static vector3 refract(const vector3 &v, const vector3 &n, float ni_over_nt)
    {
        const vector3 uv = v.normalized();
        const float dt = dot(uv, n);
        const float discriminant = 1.0f - ni_over_nt * ni_over_nt * (1 - dt * dt);
        if (discriminant > 0)
        {
            return (uv - n * dt) * ni_over_nt - n * std::sqrt(discriminant);
        }
        return reflect(v, n);
    }
};

typedef vector3 color;
typedef vector3 point3;

inline vector3 random_unit_vector() {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_real_distribution<float> dis(0.0f, 1.0f);
    float z = dis(gen) * 2.0f - 1.0f;
    float a = dis(gen) * 2.0f * 3.14159265359f;
    float r = std::sqrt(1.0f - z * z);
    float x = r * std::cos(a);
    float y = r * std::sin(a);
    return vector3(x, y, z);
}

inline vector3 mix(const vector3& a, const vector3& b, float t) {
    return a * (1.0f - t) + b * t;
}

#include <metal/metal_stdlib>
#include <metal_logging>

#include "definitions.h"

using namespace metal;

Shader_RenderState hit(Shader_Ray ray, Shader_Sphere sphere, float tMin, float tMax, Shader_RenderState renderState);

Shader_RenderState trace(Shader_Ray ray, float sphereCount, const device Shader_Sphere* spheres);

constant float PHI = 1.61803398874989484820459; 
constant float PI = 3.141592653589793238;

float reflectance(float cosine, float refraction_index){
    float r0 = (1-refraction_index)/(1+refraction_index);
    r0 = r0*r0;
    return r0 + (1-r0)*pow((1-cosine), 5.0);
}

float random(uint state){
    state = state * 747796405 + 2891336453;
    uint result = ((state >> ((state >> 28) + 4)) ^ state) * 277803737;
    result = (result >> 22) ^ result;
    return result / 4294967295.f;
}

float random(uint state,float min,float max){
    return min + (max-min)*random(state);
}




float3 randomVec(float2 xy, float seed) {
    uint hold = pow(xy[0],5)*pow(xy[1],3)*floor(seed);
    return float3(random(hold),random(hold*100),random(hold*1000));
}

vector_float3 unit_vector(vector_float3 vec){
    return vec/sqrt(vec[0]*vec[0]+vec[1]*vec[1]+vec[2]*vec[2]);
}

bool near_zero(float3 vec){
    float s = 1e-8;
    return (vec[0] < s) && (vec[1] < s) && (vec[2] < s);
}

float3 ray_color(Shader_Ray ray, constant Shader_SceneData &sceneData, const device Shader_Sphere* spheres);



vector_float3 at (const Shader_Ray r, float t){
    return r.origin + t*r.direction;
}


vector_float3 random_unit_vector(int x, int y,int z){
    return unit_vector(randomVec(float2(z,y), x));
}

vector_float3 random_on_hemisphere(const vector_float3 normal,int x, int y, int z){
    vector_float3 on_unit_sphere = random_unit_vector(x, y, z);
    if (dot(on_unit_sphere,normal) > 0.0){
        return on_unit_sphere;
    }
    else {
        return -on_unit_sphere;
    }
}

float clamp(float x, float max, float min) {
    if (x < min){
        return min;
    }
    if (x > max){
        return max;
    }
    return x;
}

float hit_sphere(Shader_Sphere sphere, const Shader_Ray r){
    vector_float3 oc = sphere.center - r.origin;
    float a = dot(r.direction, r.direction);
    float h = dot(r.direction,oc);
    float c = dot(oc,oc) - sphere.radius*sphere.radius;
    float discriminant = h*h - a*c;
    if (discriminant < 0){
        return -1.0;
    } else {
        return (h-sqrt(discriminant))/a;
    }
}



Shader_RenderState hit(Shader_Ray r, Shader_Sphere sphere, float tMin, float tMax, Shader_RenderState renderState){
    vector_float3 oc = sphere.center - r.origin;
    float a = dot(r.direction, r.direction);
    float h = dot(r.direction,oc);
    float c = dot(oc,oc) - sphere.radius*sphere.radius;
    float discriminant = h*h - a*c;
    if (discriminant > 0){
        float t = (h-sqrt(discriminant))/a;
        if (t > tMin && t < tMax){
            renderState.t = t;
            renderState.color = sphere.color;
            renderState.material = sphere.material;
            renderState.hit = 1.0;
            renderState.position = r.origin + t * r.direction;
            renderState.normal = normalize(renderState.position - sphere.center);
            renderState.reflectance = sphere.reflectance;
            renderState.front_face = 1.0;
            renderState.other = sphere.other;
            return renderState;
        }
        t = (h+sqrt(discriminant))/a;
        if (t > tMin && t < tMax){
            renderState.t = t;
            renderState.color = sphere.color;
            renderState.material = sphere.material;
            renderState.hit = 1.0;
            renderState.position = r.origin + t * r.direction;
            renderState.normal = normalize(renderState.position - sphere.center);
            renderState.reflectance = sphere.reflectance;
            renderState.front_face = 0.0;
            return renderState;
        }
    }
    renderState.hit = 0.0;
    return renderState;
}


float3 ray_color(Shader_Ray ray, constant Shader_SceneData &sceneData, const device Shader_Sphere* spheres, int x, int y) {
    float3 attenuation[32];
    for (int i = 0; i < sceneData.maxBounces; i++){
        attenuation[i] = float3(1.0,1.0,1.0);
    }
    Shader_RenderState result = trace(ray, sceneData.sphereCount, spheres);

    float missed = 0.0;
    float cos_theta = 0.0;
    for (int i = 0; i < sceneData.maxBounces; i++) {
        if (!result.hit) {
            missed = 1.0;
            break;
        }
        float3 origin = result.position;
        if (result.material <= 1.0 && result.material < 2.0){
            float3 direction = random_on_hemisphere(result.normal, pow(x,2.0),pow(i,2.6),pow(y,4.1));
            float3 unit_direction = unit_vector(ray.direction);
            cos_theta = min(dot(-unit_direction,result.normal),1.0);
            attenuation[i] = result.color;
            ray.origin= origin;
            ray.direction = direction;
            
        }
        if (result.material <= 2.0 && result.material < 3.0){
            float3 direction = reflect(ray.direction, result.normal);
            direction = unit_vector(direction) + (result.other*randomVec(float2(i,y), x));
            float3 unit_direction = unit_vector(ray.direction);
            cos_theta = min(dot(-unit_direction,result.normal),1.0);
            attenuation[i] = result.color;
            ray.origin= origin;
            ray.direction = direction;
        }
        else {
            float ri = 0.0;
            if (result.front_face == 1.0){
                ri = (1/result.other);
            }
            else {
                ri = result.other;
                result.normal = -result.normal;
            }
            float3 unit_direction = unit_vector(ray.direction);
            cos_theta = min(dot(-unit_direction,result.normal),1.0);
            float sin_theta = sqrt(1.0 - cos_theta*cos_theta);
            bool cannot_refract = ri*sin_theta > 1.0;
            float3 direction = float3(0);
            if (cannot_refract || reflectance(cos_theta,ri) > random(pow(x,5.0)*pow(y,4.0))){
                direction = reflect(unit_direction, result.normal);
            }
            else {
                direction = refract(unit_direction, unit_vector(result.normal), ri);
            }
            ray.origin = origin;
            ray.direction = direction;
        }
        
        result = trace(ray, sceneData.sphereCount, spheres);
    }
    if (missed==0.0){
        return float3(0);
    }
    float3 unitdirection = unit_vector(ray.direction);
    float a = 0.5*(unitdirection[1]+1.0) ;
    float3 color = (1.0-a)*float3(1.0)+a*float3(0.5,0.7,1.0);
    for (int i = 0; i < sceneData.maxBounces; i++){
        color *= attenuation[i];
    }
    return color;
}


Shader_RenderState trace(const Shader_Ray r, float sphereCount, const device Shader_Sphere* spheres){
    float3 color = float3(1.0);
    float nearestHit = 9999;
    Shader_RenderState renderState;
    renderState.hit = 0.0;
    for (int i = 0; i < sphereCount; i++){
        Shader_RenderState newRenderState = hit(r,spheres[i], 0.001, nearestHit, renderState);
        if (newRenderState.hit > 0.1){
            nearestHit = newRenderState.t;
            renderState = newRenderState;
            color = renderState.color;
        }
    }
    renderState.color = color;
    return renderState;
}


kernel void ray_tracing_kernel(texture2d<float, access::write> color_buffer[[texture(0)]], const device Shader_Sphere *spheres [[buffer(0)]], constant Shader_SceneData &scenedata [[buffer(1)]], uint2 grid_index [[thread_position_in_grid]]){
    int width = color_buffer.get_width();
    int height = color_buffer.get_height();
    float focal_length = 1.0;
    float viewport_height = 2.0;
    float viewport_width = viewport_height * (float(width)/height);
    vector_float3 camera_point = scenedata.camera_pos;
    vector_float3 viewport_u = float3(viewport_width, 0.0 ,0.0)*scenedata.camera_forwards;
    vector_float3 viewport_v = float3(0.0, -viewport_height ,0.0)*-scenedata.camera_right;
    vector_float3 delta_u = viewport_u / width;
    vector_float3 delta_v = viewport_v / height;
    vector_float3 upper_left = camera_point - float3(0.0,0.0,focal_length)*scenedata.camera_up - viewport_u/2 - viewport_v/2;
    vector_float3 firstPixel = upper_left + 0.5*(delta_u+delta_v);
    float sample_per_pixels = 1.0;
    vector_float3 color = (0.0);

    for (int i = 0; i < sample_per_pixels; i++){
        uint hold = pow(grid_index[0],2.0)*pow(grid_index[1],3.0)*i;
        vector_float3 sample_square = float3(random(hold) - 0.5, random(pow(grid_index[0],4.0)*pow(grid_index[1],5.0)) - 0.5,0);
        vector_float3 pixel = firstPixel + delta_u*(grid_index.x+sample_square[0]) + delta_v*(grid_index.y+sample_square[1]);
        vector_float3 raydirection = pixel-camera_point;
        Shader_Ray r = {camera_point,raydirection};
        color += ray_color(r,scenedata,spheres, grid_index[0],grid_index[1]);
    }
    color *= 1.0/sample_per_pixels;
    color_buffer.write(float4(color,1.0),grid_index);
}

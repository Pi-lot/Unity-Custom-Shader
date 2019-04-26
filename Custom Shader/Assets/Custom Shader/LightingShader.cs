using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightingShader : MonoBehaviour {
    // Lights within the scene
    [SerializeField] private Light[] lights;

    // Is this attached to the car model
    [SerializeField] private bool isCar = false;

    // Use this for initialization
    void Start() {
    }

    // Update is called once per frame
    void Update() {
        // Get the lights in the scene
        lights = Manager.instance.GetLights();

        // Loop through all the lights and update the required shader values
        int index = 0; // Used to update the correct spot light
        foreach (Light light in lights) {
            if (light.type.Equals(LightType.Directional)) { // Main directional light
                if (!isCar) { // Check if this gameObject is the car, if not update material, 
                    GetComponent<Renderer>().material.SetColor("_lightColour", light.color);
                    GetComponent<Renderer>().material.SetVector("_vecLightPos", new Vector4(light.transform.position.x, light.transform.position.y, light.transform.position.z, 0));
                    GetComponent<Renderer>().material.SetFloat("_lightIntensity", light.intensity);
                    Camera depthCam = light.GetComponent<Camera>();
                    GetComponent<Renderer>().material.SetMatrix("_ProjMatrixSun", depthCam.projectionMatrix * depthCam.worldToCameraMatrix);
                } else { // If so get the materials and update them all
                    Material[] materials = GetComponent<MeshRenderer>().materials;

                    foreach (Material mat in materials) {
                        mat.SetColor("_lightColour", light.color);
                        mat.SetVector("_vecLightPos", new Vector4(light.transform.position.x, light.transform.position.y, light.transform.position.z, 0));
                        mat.SetFloat("_lightIntensity", light.intensity);

                        Camera depthCam = light.GetComponent<Camera>();
                        GetComponent<Renderer>().material.SetMatrix("_ProjMatrixSun", depthCam.projectionMatrix * depthCam.worldToCameraMatrix);
                    }
                }
            } else if (light.type.Equals(LightType.Spot)) { // Spot lights
                if (index == 0) { // First spot light
                    if (!isCar) {
                        GetComponent<Renderer>().material.SetVector("_vecSpotLight0Pos", new Vector4(light.transform.position.x, light.transform.position.y, light.transform.position.z, 0));
                        GetComponent<Renderer>().material.SetVector("_vecSpotLight0Dir", new Vector4(light.transform.forward.x, light.transform.forward.y, light.transform.forward.z, 0));
                        GetComponent<Renderer>().material.SetFloat("_spotLight0Intensity", light.intensity);
                        GetComponent<Renderer>().material.SetFloat("_spotLight0Angle", light.spotAngle);

                        Camera depthCam = light.GetComponent<Camera>();
                        GetComponent<Renderer>().material.SetMatrix("_ProjMatrixSpot0", depthCam.projectionMatrix * depthCam.worldToCameraMatrix);
                        GetComponent<Renderer>().material.SetTexture("_ShadowMapSpot0", depthCam.targetTexture);
                    } else {
                        Material[] materials = GetComponent<MeshRenderer>().materials;

                        foreach (Material mat in materials) {
                            mat.SetVector("_vecSpotLight0Pos", new Vector4(light.transform.position.x, light.transform.position.y, light.transform.position.z, 0));
                            mat.SetVector("_vecSpotLight0Dir", new Vector4(light.transform.forward.x, light.transform.forward.y, light.transform.forward.z, 0));
                            mat.SetFloat("_spotLight0Intensity", light.intensity);
                            mat.SetFloat("_spotLight0Angle", light.spotAngle);

                            Camera depthCam = light.GetComponent<Camera>();
                            mat.SetMatrix("_ProjMatrixSpot0", depthCam.projectionMatrix * depthCam.worldToCameraMatrix);
                            mat.SetTexture("_ShadowMapSpot0", depthCam.targetTexture);
                        }
                    }
                } else { // Second spot light
                    if (!isCar) {
                        GetComponent<Renderer>().material.SetVector("_vecSpotLight1Pos", new Vector4(light.transform.position.x, light.transform.position.y, light.transform.position.z, 0));
                        GetComponent<Renderer>().material.SetVector("_vecSpotLight1Dir", new Vector4(light.transform.forward.x, light.transform.forward.y, light.transform.forward.z, 0));
                        GetComponent<Renderer>().material.SetFloat("_spotLight1Intensity", light.intensity);
                        GetComponent<Renderer>().material.SetFloat("_spotLight1Angle", light.spotAngle);

                        Camera depthCam = light.GetComponent<Camera>();
                        GetComponent<Renderer>().material.SetMatrix("_ProjMatrixSpot1)", depthCam.projectionMatrix * depthCam.worldToCameraMatrix);
                        GetComponent<Renderer>().material.SetTexture("_ShadowMapSpot1", depthCam.targetTexture);
                    } else {
                        Material[] materials = GetComponent<MeshRenderer>().materials;

                        foreach (Material mat in materials) {
                            mat.SetVector("_vecSpotLight1Pos", new Vector4(light.transform.position.x, light.transform.position.y, light.transform.position.z, 0));
                            mat.SetVector("_vecSpotLight1Dir", new Vector4(light.transform.forward.x, light.transform.forward.y, light.transform.forward.z, 0));
                            mat.SetFloat("_spotLight1Intensity", light.intensity);
                            mat.SetFloat("_spotLight1Angle", light.spotAngle);

                            Camera depthCam = light.GetComponent<Camera>();
                            mat.SetMatrix("_ProjMatrixSpot1", depthCam.projectionMatrix * depthCam.worldToCameraMatrix);
                            mat.SetTexture("_ShadowMapSpot1", depthCam.targetTexture);
                        }
                    }
                }

                index++;
            } else {
                if (!isCar) { // Check if this gameObject is the car, if not update material, 
                    GetComponent<Renderer>().material.SetVector("_vecFirePos", new Vector4(light.transform.position.x, light.transform.position.y, light.transform.position.z, 0));
                    GetComponent<Renderer>().material.SetFloat("_fireIntensity", light.intensity);
                } else { // If so get the materials and update them all
                    Material[] materials = GetComponent<MeshRenderer>().materials;

                    foreach (Material mat in materials) {
                        mat.SetVector("_vecFirePos", new Vector4(light.transform.position.x, light.transform.position.y, light.transform.position.z, 0));
                        mat.SetFloat("_fireIntensity", light.intensity);
                    }
                }
            }
        }

        // Get the camera and update the camera position in the shader
        Camera mainCamera = Manager.instance.GetCamera();
        if (!isCar) { // Check if this gameObject is the car, if not update material, 
            GetComponent<Renderer>().material.SetVector("_vecCameraPos", new Vector4(mainCamera.transform.position.x, mainCamera.transform.position.y, mainCamera.transform.position.z));
        } else { // If so get the materials and update them all
            Material[] materials = GetComponent<MeshRenderer>().materials;

            foreach (Material mat in materials) {
                mat.SetVector("_vecCameraPos", new Vector4(mainCamera.transform.position.x, mainCamera.transform.position.y, mainCamera.transform.position.z));
            }
        }

    }
}
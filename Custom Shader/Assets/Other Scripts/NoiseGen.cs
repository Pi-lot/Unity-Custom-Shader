using System.Collections;
using System.Collections.Generic;
using SimplexNoise;
using UnityEngine;

public class NoiseGen : MonoBehaviour {

    private Texture3D tex;
    private int size = 64;

    // Use this for initialization
    void Start() {
        // Generate texture
        tex = new Texture3D(size, size, size, TextureFormat.ARGB32, true);
        var cols = new Color[size * size * size];

        int idx = 0;
        Color c = Color.white;

        for (int z = 0; z < size; ++z) {
            for (int y = 0; y < size; ++y) {
                for (int x = 0; x < size; ++x, ++idx) {
                    c.r = Noise.Generate(x + transform.position.x, y + transform.position.y, z + transform.position.z);
                    c.g = c.r;
                    c.b = c.r;
                    cols[idx] = c;
                }
            }
        }

        tex.SetPixels(cols);
        tex.Apply();
        GetComponent<Renderer>().material.SetTexture("VolumeTexture", tex);
    }

    // Update is called once per frame
    void Update() {

    }
}

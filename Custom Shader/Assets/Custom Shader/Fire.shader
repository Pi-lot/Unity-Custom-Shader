// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// File: Flame.shader 
// Author: Ross Brown - r.brown@qut.edu.au
// Updated: 20/04/2015
// Description: Volumetric flame effect	based on Yury Uralsky's "Volumetric Fire" http://www.cgshaders.org/shaders/show.php?id=39
//

Shader "Fire"
{
	Properties
	{
		VolumeTexture("Base (RGB)", 3D) = "white" {}
		FlameTexture("Base (RGB)", 2D) = "white" {}
	}

		SubShader
	{
		Pass
		{

		CGPROGRAM
		#pragma vertex flameVS
		#pragma fragment flamePS
		#pragma target 3.0

		/************* TWEAKABLES **************/

		static float noiseFreq = 0.1;
		static float noiseStrength = 1.0;

		static float timeScale = 1.0;

		static float3 noiseScale = { 1.0, 1.0, 1.0 };
		static float3 noiseAnim = { 0.0, -0.1, 0.0 };

		static float4 flameColor = { 0.4, 0.4, 0.4, 1.0 };
		static float3 flameScale = { 1.0, -1.0, 1.0 };
		static float3 flameTrans = { 0.0, 0.0, 0.0 };

		// Textures /////////////////

		sampler3D VolumeTexture;
		sampler2D FlameTexture;

		//////////////////////////////

		// Structures
		struct appdata
		{
			float3 Position	: POSITION;
			float4 UV		: TEXCOORD0;
			float4 Normal	: NORMAL;
		};

		struct vertexOutput
		{
			float4 HPosition	: POSITION;
			float3 NoisePos     : TEXCOORD0;
			float3 FlamePos     : TEXCOORD1;
			float2 UV           : TEXCOORD2;
		};

		// Vertex shader
		vertexOutput flameVS(appdata IN)
		{
			vertexOutput OUT;

			float4 objPos = float4(IN.Position.x, IN.Position.y, IN.Position.z, 1.0f);
			float3 worldPos = mul(unity_ObjectToWorld, IN.Position).xyz;

			OUT.HPosition = UnityObjectToClipPos(objPos);
			float time = fmod(_Time.y, 10.0f);	// avoid large texcoords
			OUT.NoisePos = worldPos * noiseScale * noiseFreq + time * timeScale * noiseAnim;
			OUT.FlamePos = worldPos * flameScale + flameTrans;

			OUT.UV = IN.UV;

			return OUT;
		}

		// Pixel shaders
		half4 noise3D(uniform sampler3D NoiseMap, float3 P)
		{
			return tex3D(NoiseMap, P) / 2.0f + 0.5f;
		}

		half4 turbulence4(uniform sampler3D NoiseMap, float3 P)
		{
			half4 sum = noise3D(NoiseMap, P) * 0.5f +
						noise3D(NoiseMap, P * 2) * 0.25f +
						noise3D(NoiseMap, P * 4) * 0.125f +
						noise3D(NoiseMap, P * 8) * 0.0625f;
			return sum;
		}

		half4 flamePS(vertexOutput IN) : COLOR
		{
			half2 uv;

			uv.x = length(IN.FlamePos.xz);	// radial distance in XZ plane
			uv.y = IN.FlamePos.y;

			uv.y += turbulence4(VolumeTexture, IN.NoisePos) * noiseStrength / uv.x;

			return tex2D(FlameTexture, uv) * flameColor;
		}

		ENDCG
		}
	}
}

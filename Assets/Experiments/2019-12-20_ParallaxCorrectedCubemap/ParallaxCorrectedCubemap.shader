Shader "Unlit/ParallaxCorrectedCubemap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // ParallaxCorrectedCubemap
            float3 _BoxMax;
            float3 _BoxMin;
            float3 _CubemapPos;

            // Parallax-Corrected Cubemap
            // https://seblagarde.files.wordpress.com/2012/08/parallax_corrected_cubemap-siggraph2012.pdf
            half3 calcParallaxCorrectedCubemapReflect(float3 worldPos, half3 worldNormal, half3 worldRefl)
            {
                float3 firstPlaneIntersect  = (_BoxMax - worldPos) / worldRefl;
                float3 secondPlaneIntersect = (_BoxMin - worldPos) / worldRefl;
                float3 furthestPlane = max(firstPlaneIntersect, secondPlaneIntersect);
                float dist = min(min(furthestPlane.x, furthestPlane.y), furthestPlane.z);
                float3 worldIntersectPos = worldPos + worldRefl * dist;
                return worldIntersectPos - _CubemapPos;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv2 = v.uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // Lightmap
                half4 lmtex = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2);
                half3 lmap = DecodeLightmap(lmtex);
                col.rgb *= lmap.rgb;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}

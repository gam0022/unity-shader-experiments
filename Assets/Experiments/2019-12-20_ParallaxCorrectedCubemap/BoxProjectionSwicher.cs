using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class BoxProjectionSwicher : MonoBehaviour
{
    [SerializeField] TextMeshProUGUI textMeshPro;
    [SerializeField] ReflectionProbe reflectionProbe;

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            reflectionProbe.boxProjection = !reflectionProbe.boxProjection;
        }

        textMeshPro.text = "Box Projection: " + (reflectionProbe.boxProjection ? "ON" : "OFF");
    }
}

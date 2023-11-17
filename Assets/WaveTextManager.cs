using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using NaughtyWaterBuoyancy;

public class WaveTextManager : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI waveText;
    public WaterWaves waveData;
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        waveText.text = "WaveSpeed : " + Mathf.Round(waveData.speed).ToString();
    }
}

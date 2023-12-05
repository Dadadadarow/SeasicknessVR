using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using UnityEngine;
using UnityEngine.UI;

public class TCPHandler : MonoBehaviour
{
    public String Host = "localhost";
    public Int32 Port = 55001;
    public String msg; //message
    public float decodedValue;

    private TcpListener listener = null;
    private TcpClient client = null;
    private NetworkStream ns = null;

    void Awake()
    {
        listener = new TcpListener(Dns.GetHostEntry(Host).AddressList[1], Port);
        listener.Start();
        Debug.Log("is listening...");

        if (listener.Pending())
        {
            client = listener.AcceptTcpClient();
            Debug.Log("Connected!");
        }
    }

    void Update()
    {
        if (client == null)
        {
            if (listener.Pending())
            {
                client = listener.AcceptTcpClient();
                Debug.Log("Connected!");
            }
            else
            {
                return;
            }
        }
        ns = client.GetStream();

        if ((ns != null) && (ns.DataAvailable))
        {
            StreamReader reader = new StreamReader(ns);
            String temp = reader.ReadLine();
            if (temp != null)
                msg = temp;
            Debug.Log(msg);
            decodedValue = float.Parse(msg);
        }
        
        // press space to restart the listening
        if (Input.GetKeyDown("space"))
        {
            listener.Start();
            client = listener.AcceptTcpClient();
        }
    }

    private void OnApplicationQuit()
    {
        if (listener != null)
        {
            listener.Stop();
            Debug.Log("Connection terminated.");
        }
    }
}
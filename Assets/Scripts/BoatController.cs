using UnityEngine;

public class BoatController : MonoBehaviour
{
    public TaskManager taskManager;
    public float forwardForce = 200f; // 前進の力
    public float rotationSpeed = 400f; // 回転の速度

    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        if (taskManager.isMove)
        {
            Debug.Log("Random moving");
            Vector3 randomForce = new Vector3(1f, 0f, 0f);
            rb.AddForce(randomForce*forwardForce);
            rb.AddTorque(transform.up * Random.Range(50, rotationSpeed));
        }
    }
}

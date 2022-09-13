#include "DHT.h"
#include <SoftwareSerial.h>

// Temperature and Humidity Sensor Pin
#define DHTPIN 2
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// Bluetooth Serial to send and receive
SoftwareSerial bluetoothSerial(5, 4); // RX, TX

#define pinGREEN 12
#define pinRED 11
#define pinBLUE 10

unsigned long lastSentTime = 0;
int rd = 0;
int gr = 0;
int bl = 0;

void setup()
{
  Serial.begin(115200);
  bluetoothSerial.begin(115200);

  // Serial timeout default is 1000ms. Adjust this to your preference.
  bluetoothSerial.setTimeout(100);

  pinMode(pinGREEN, OUTPUT);
  pinMode(pinRED, OUTPUT);
  pinMode(pinBLUE, OUTPUT);

  dht.begin();
}

void loop()
{
  commands();
  sendReading();
}

void commands()
{
  // phone send ,arduino receive
  if (bluetoothSerial.available())
  {
    String serialReceived = bluetoothSerial.readStringUntil('\n');

    if (serialReceived == "red on")
    {
      digitalWrite(pinRED, HIGH);
      rd = 1;
      bluetoothSerial.println("RD:1;");
    }
    else if (serialReceived == "red off")
    {
      digitalWrite(pinRED, LOW);
      rd = 0;
      bluetoothSerial.println("RD:0;");
    }
    else if (serialReceived == "green on")
    {
      digitalWrite(pinGREEN, HIGH);
      gr=1;
      bluetoothSerial.println("GR:1;");
    }
    else if (serialReceived == "green off")
    {
      digitalWrite(pinGREEN, LOW);
      gr=0;
      bluetoothSerial.println("GR:0;");
    }
    else if (serialReceived == "blue on")
    {
      digitalWrite(pinBLUE, HIGH);
      bl=1;
      bluetoothSerial.println("BL:1;");
    }
    else if (serialReceived == "blue off")
    {
      digitalWrite(pinBLUE, LOW);
      bl=0;
      bluetoothSerial.println("BL:0;");
    }
  }
}

void sendReading()
{
  if ((millis() - lastSentTime) >= 1000)
  {
    float temp = dht.readTemperature();
    float humid = dht.readHumidity();

    Serial.print("Temperature: ");
    Serial.print(temp);
    Serial.println(" *C ");
    Serial.print("Humidity: ");
    Serial.print(humid);
    Serial.println(" % ");
    Serial.println("===========================");

    // arduino send, phone receive
    bluetoothSerial.println("TP:" + String(temp) + ";");
    bluetoothSerial.println("RD:" + String(rd) + ";");
    bluetoothSerial.println("GR:" + String(gr) + ";");
    bluetoothSerial.println("BL:" + String(bl) + ";");
    bluetoothSerial.print("HD:" + String(humid) + ";");

    lastSentTime = millis();
  }
}

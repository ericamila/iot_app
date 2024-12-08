#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <ambiente.ino> //#define WIFI_SSID WIFI_PASSWORD API_KEY DATABASE_URL

#define LED1_PIN 12
#define LED2_PIN 14
#define LDR_PIN 36
#define PWMChannel 0

const int freq = 5000;
const int resolution = 8;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
int ldrData = 0;
bool signupOK = false;
float voltage = 0.0;
int pwmValue = 0;
bool ledStatus = false;

void setup() {
  pinMode(LED2_PIN, OUTPUT);
  //ledcSetup(PWMChannel, freq, resolution);
  //ledcAttach(LED1_PIN, PWMChannel);

  Serial.begin(115200);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("signUp ok");
    signupOK = true;
  } else {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
    Serial.println("AIzaSyA4bWr1rJAmBmUhR66Pbbnj4wocw16T4n8");
  }


  /* Assign the callback function for the long running token generation task */
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectNetwork(true);
}

void loop() {
  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    ldrData = analogRead(LDR_PIN);
    voltage = (float)analogReadMilliVolts(LDR_PIN) / 1000;
    if (Firebase.RTDB.setInt(&fbdo, "Sensor/ldr_data", ldrData)) {
      Serial.println();
      Serial.print(ldrData);
      Serial.print(" successfully saved to:" + fbdo.dataPath());
      Serial.println(" (" + fbdo.dataType() + ")");
    } else {
      Serial.println("FAILED: " + fbdo.errorReason());
    }
    if (Firebase.RTDB.setFloat(&fbdo, "Sensor/voltage", voltage)) {
      Serial.println();
      Serial.print(voltage);
      Serial.print(" successfully saved to:" + fbdo.dataPath());
      Serial.println(" (" + fbdo.dataType() + ")");
    } else {
      Serial.println("FAILED: " + fbdo.errorReason());
    }
  }

  if (Firebase.RTDB.getInt(&fbdo, "/LED/analog/")) {
    if (fbdo.dataType() == "int") {
      pwmValue = fbdo.intData();
      Serial.println("Successful READ from " + fbdo.dataPath() + ": " + pwmValue + " (" + fbdo.dataType() + ")");
      ledcWrite(PWMChannel, pwmValue);
    }
  } else {
    Serial.println("FAILED: " + fbdo.errorReason());
  }

  if (Firebase.RTDB.getBool(&fbdo, "/LED/digital/")) {
    if (fbdo.dataType() == "boolean") {
      ledStatus = fbdo.boolData();
      Serial.println("Successful READ from " + fbdo.dataPath() + ": " + ledStatus + " (" + fbdo.dataType() + ")");
      ledcWrite(LED2_PIN, ledStatus);
    }
  } else {
    Serial.println("FAILED: " + fbdo.errorReason());
  }

}
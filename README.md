# iot_app

CRUD simples com RealTime database

### Preparar seu espaço de trabalho
Instalar a [CLI](https://firebase.google.com/docs/cli?hl=pt&authuser=0&_gl=1*lcnsah*_ga*MTU5NjQ2MjgxMS4xNzMzMzUwMjk4*_ga_CW55HF8NVT*MTczMzY2ODgzMS4xOS4xLjE3MzM2Njg4MzcuNTQuMC4w#install_the_firebase_cli) do Firebase  e fazer login (execute firebase login)

````
firebase login
firebase projects:list

firebase init
````
-> Realtime Database



### Instalar e executar a CLI do FlutterFire
````
dart pub global activate flutterfire_cli

flutterfire configure --project=iot-app-ufrr

ou firebase apps:create android iot_app (android) --package-name= --json --project=iot-app-ufrr

````

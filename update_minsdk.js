const fs = require('fs');
let content = fs.readFileSync('android/app/build.gradle.kts', 'utf-8');
content = content.replace('minSdk = flutter.minSdkVersion', 'minSdk = 23');
fs.writeFileSync('android/app/build.gradle.kts', content, 'utf-8');
console.log("Updated minSdk to 23");

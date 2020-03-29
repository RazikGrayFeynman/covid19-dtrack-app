COVID-19 India DTrack Mobile App
---
A mobile app to serve as a central basis for all COVID-19 related
tracking

Overview
---
This mobile app is an attempt to build a privacy-first, distributed
app to aid the contact tracing process. Some of the salient features are - 

1. Built in Flutter, so can target both iOS and Android with one codebase
2. All data is stored locally, only minimal data is shared when required

Roadmap
---

### Top level goal
Basically, this app aims to collect information that can be used to
obtain high-fidelity contact tracing. The possible information is -

1. Bluetooth - store bluetooth devices seen
2. Wifi - store access points seen
3. GPS - store GPS locations visited

Once this data is stored locally, a central database of suspect cases
are regularly forwarded to the app, which can be used to cross-check
and investigate if someone could possible be infected

### Bluetooth
Here is the deal with Bluetooth -
1. Both Android and iOS limit the amount of information they share with
the apps for Bluetooth. 
2. The plan is to register this app as a Bluetooth peripheral which advertises
a UUID. Other phones, scan this advertisement and update the UUID


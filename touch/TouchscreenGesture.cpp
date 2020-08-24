/*
 * Copyright (C) 2019 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "TouchscreenGestureService"

#include <fstream>

#include <android-base/file.h>
#include <android-base/logging.h>

#include "TouchscreenGesture.h"

namespace vendor {
namespace lineage {
namespace touch {
namespace V1_0 {
namespace implementation {

const std::string kAvailableGesturePath = "/sys/devices/virtual/input/lge_touch/swipe_available"; 
const std::string kGesturePath = "/sys/devices/virtual/input/lge_touch/swipe_enable"; 
const char* kGestureNames[6] = {
    "Swipe Down",
    "Swipe Up",
    "Swipe Right",
    "Swipe Left",
    "Swipe Bottom Right",
    "Swipe Bottom Left",
};
bool gestureAvailable[6] = {false, false, false, false, false, false };

TouchscreenGesture::TouchscreenGesture() {
    std::ifstream file(kAvailableGesturePath);
    std::string line;
    while(getline(file, line)) {
        if(line == "0 1") {
            gestureAvailable[0] = true;
        } else if(line == "1 1") {
            gestureAvailable[1] = true;
        } else if(line == "2 1") {
            gestureAvailable[2] = true;
        } else if(line == "3 1") {
            gestureAvailable[3] = true;
        } else if(line == "4 1") {
            gestureAvailable[4] = true;
        } else if(line == "5 1") {
            gestureAvailable[5] = true;
        }
    }
    for(int i = 0, j = 0; i < 6; i++) {
        if(gestureAvailable[i]) {
            GestureInfo g = {i, 247+i, kGestureNames[i]};
            kGestureInfoMap.emplace(j, g);
            j++;
        }
    }
}

Return<void> TouchscreenGesture::getSupportedGestures(getSupportedGestures_cb resultCb) {
    std::vector<Gesture> gestures;

    for (const auto& entry : kGestureInfoMap) {
        gestures.push_back({entry.first, entry.second.name, entry.second.keycode});
    }
    resultCb(gestures);

    return Void();
}

Return<bool> TouchscreenGesture::setGestureEnabled(
    const ::vendor::lineage::touch::V1_0::Gesture& gesture, bool enable) {

    std::ofstream file(kGesturePath);
    std::map<int32_t, GestureInfo>::iterator it;
    it = kGestureInfoMap.find(gesture.id);
    if(it == kGestureInfoMap.end()) {
        return false;
    }
    GestureInfo gi = it->second;

    std::string output = std::to_string(gi.swipe_id) + " " + std::to_string(enable);
    
    file << output;

    return !file.fail();
}

}  // namespace implementation
}  // namespace V1_0
}  // namespace touch
}  // namespace lineage
}  // namespace vendor

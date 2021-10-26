/*
 * Copyright (C) 2017 The LineageOS Project
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

#define LOG_TAG "LightService"

#include "Light.h"
#include <log/log.h>
#include <android-base/stringprintf.h>

namespace android {
namespace hardware {
namespace light {
namespace V2_0 {
namespace implementation {

/*
 * Write value to path and close file.
 */
template <typename T>
static void set(const std::string& path, const T& value) {
    std::ofstream file(path);
    file << value;
}

template <typename T>
static T get(const std::string& path, const T& def) {
    std::ifstream file(path);
    T result;

    file >> result;
    return file.fail() ? def : result;
}

static int rgbToBrightness(const LightState& state) {
    int color = state.color & 0x00ffffff;
    return ((77 * ((color >> 16) & 0x00ff))
            + (150 * ((color >> 8) & 0x00ff))
            + (29 * (color & 0x00ff))) >> 8;
}

static bool isLit(const LightState& state) {
    return (state.color & 0x00ffffff);
}

void Light::setLightLocked(const LightState& state) {
    int onMS, offMS;
    uint32_t color;
    char pattern[PAGE_SIZE];

    switch (state.flashMode) {
        case Flash::TIMED:
            onMS = state.flashOnMs;
            offMS = state.flashOffMs;
            break;
        case Flash::NONE:
            onMS = 0;
            offMS = 0;
            break;
        default:
            onMS = -1;
            offMS = -1;
            break;
    }

    color = state.color & 0x00ffffff;

    if (offMS <= 0) {
        sprintf(pattern,"0x%06x", color);
        ALOGD("%s: Using onoff pattern: inColor=0x%06x\n", __func__, color);
        set(LED ONOFF_PATTERN, pattern);
    } else {
        sprintf(pattern,"0x%06x,%d,%d", color, onMS, offMS);
        ALOGD("%s: Using blink pattern: inColor=0x%06x delay_on=%d, delay_off=%d\n",
              __func__, color, onMS, offMS);
        set(LED BLINK_PATTERN, pattern);
    }
}

void Light::checkLightStateLocked() {
    if (isLit(mNotificationState)) {
        setLightLocked(mNotificationState);
    } else if (isLit(mAttentionState)) {
        setLightLocked(mAttentionState);
    } else if (isLit(mBatteryState)) {
        setLightLocked(mBatteryState);
    } else {
        /* Lights off */
        set(LED BLINK_PATTERN, "0x0,-1,-1");
        set(LED ONOFF_PATTERN, "0x0");
    }
}

void Light::handleAttention(const LightState& state) {
    mAttentionState = state;
    checkLightStateLocked();
}

void Light::handleBacklight(const LightState& state) {
    int brightness, brightnessEx;
    int sentBrightness = rgbToBrightness(state);
    if(sentBrightness < 35) {
        brightness = sentBrightness * 2;
        brightnessEx = sentBrightness * 2;
    } else {
        brightness = sentBrightness * mMaxBrightness / 255;
        brightnessEx = sentBrightness * mMaxBrightnessEx / 255;
    }
    set(BL BRIGHTNESS, brightness);
    set(BL_EX BRIGHTNESS, brightnessEx);
}

void Light::handleBattery(const LightState& state) {
    mBatteryState = state;
    checkLightStateLocked();
}

void Light::handleNotifications(const LightState& state) {
    mNotificationState = state;
    checkLightStateLocked();
}

Light::Light(bool hasBacklight, bool hasBlinkPattern, bool hasOnOffPattern) {
    auto attnFn(std::bind(&Light::handleAttention, this, std::placeholders::_1));
    auto backlightFn(std::bind(&Light::handleBacklight, this, std::placeholders::_1));
    auto batteryFn(std::bind(&Light::handleBattery, this, std::placeholders::_1));
    auto notifFn(std::bind(&Light::handleNotifications, this, std::placeholders::_1));
    
    if(hasBacklight)
        mLights.emplace(Type::BACKLIGHT, backlightFn);
    
    if(hasBlinkPattern && hasOnOffPattern) {
        mLights.emplace(Type::ATTENTION, attnFn);
        mLights.emplace(Type::BATTERY, batteryFn);
        mLights.emplace(Type::NOTIFICATIONS, notifFn);
    }

    mMaxBrightness = get(BL MAX_BRIGHTNESS, -1);
    mMaxBrightnessEx = get(BL_EX MAX_BRIGHTNESS, -1);
    if (mMaxBrightness < 0) {
        mMaxBrightness = 255;
    }
    if (mMaxBrightnessEx < 0) {
        mMaxBrightnessEx = 255;
    }
}

Return<Status> Light::setLight(Type type, const LightState& state) {
    auto it = mLights.find(type);

    if (it == mLights.end()) {
        return Status::LIGHT_NOT_SUPPORTED;
    }

    /*
     * Lock global mutex until light state is updated.
     */
    std::lock_guard<std::mutex> lock(globalLock);

    it->second(state);

    return Status::SUCCESS;
}

Return<void> Light::getSupportedTypes(getSupportedTypes_cb _hidl_cb) {
    std::vector<Type> types;

    for (auto const& light : mLights) types.push_back(light.first);

    _hidl_cb(types);

    return Void();
}

}  // namespace implementation
}  // namespace V2_0
}  // namespace light
}  // namespace hardware
}  // namespace android

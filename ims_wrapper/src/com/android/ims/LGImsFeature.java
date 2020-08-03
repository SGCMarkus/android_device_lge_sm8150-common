/*
 * Copyright (C) 2020 The LineageOS Project
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

package com.android.ims;

import android.net.Uri;
import android.os.SystemProperties;
//import com.lge.sysprop.ExportedVendorProperties;
import java.io.File;

public final class LGImsFeature {
    public static final String AUTHORITY = "com.lge.ims.provider.ims_feature";
    public static final Uri CONTENT_URI = Uri.parse("content://com.lge.ims.provider.ims_feature");
    public static final String FEATURE_CDMALESS = "com.lge.ims.cdmaless";
    public static final String FEATURE_EAB = "com.lge.ims.service.eab";
    public static final String FEATURE_HVOLTE = "com.lge.ims.hvolte";
    public static final String FEATURE_JANSKY = "com.lge.ims.jansky";
    public static final String FEATURE_MEDIA_CAMERA = "com.lge.ims.media.camera";
    public static final String FEATURE_MEDIA_EVS = "com.lge.ims.media.evs";
    public static final String FEATURE_MEDIA_EVS_WB = "com.lge.ims.media.evs.wb";
    public static final int FEATURE_NO_SIM_CAPS = SystemProperties.getInt("persist.product.lge.ims.no_sim_caps", 0);
    public static final String FEATURE_RTT = "com.lge.ims.rtt";
    public static final String FEATURE_SERVER_MMPF = "com.lge.ims.mmpfservice";
    public static final String FEATURE_SERVER_SMS = "com.lge.server.ims.sms";
    public static final String FEATURE_SOFTPHONE = "com.lge.ims.softphone";
    public static final String FEATURE_VOLTE = "com.lge.ims.volte";
    public static final boolean FEATURE_VOLTE_OPEN = (SystemProperties.getInt("persist.product.lge.ims.volte_open", 0) > 0);
    public static final String FEATURE_VOWIFI = "com.lge.ims.vowifi";
    public static final String FEATURE_VT = "com.lge.ims.vt";
    public static final String FILE_XML = "com.lge.ims.xml";
    public static final String FILE_XML_CDMALESS = "com.lge.ims.cdmaless.xml";
    public static final String FILE_XML_HVOLTE = "com.lge.ims.hvolte.xml";
    public static final String FILE_XML_JANSKY = "com.lge.ims.jansky.xml";
    public static final String FILE_XML_SMS = "com.lge.server.ims.sms.xml";
    public static final String KEY_ARG_VERSION = "version";
    public static final String KEY_RESULT = "result";
    public static final boolean LAOP;
    public static final String METHOD_HAS_FEATURE = "hasFeature";
    public static final String METHOD_UPDATE_FEATURE = "updateFeature";
    public static final String PATH_CUPSS_DEFAULT = getDefaultCupssPath((String) null);
    public static final String PATH_CUPSS_ROOTDIR = SystemProperties.get("ro.vendor.lge.capp_cupss.rootdir", PATH_CUPSS_DEFAULT);
    public static final String PATH_CONFIG_ETC = (PATH_CUPSS_ROOTDIR + "/etc");
    public static final String PATH_CONFIG_LEGACY = (PATH_CUPSS_ROOTDIR + "/config");
    public static final String PATH_COTA = "/data/shared/cust/config";

    static {
        boolean lge_laop = false;
        if ("1".equals(SystemProperties.get("ro.vendor.lge.laop", "0"))) {
            lge_laop = true;
        }
        LAOP = lge_laop;
    }

    public static File getFile(String name) {
        File file = null;
        try {
            file = new File(PATH_COTA, name);
            if (!file.exists()) {
                file = new File(getCupssConfigDir(), name);
                if (!file.exists()) {
                    return null;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return file;
    }

    public static String getDefaultCupssPath(String defValue) {
        //String cupssOP = (String) ExportedVendorProperties.capp_cupss_op_dir().orElse(defValue != null ? defValue : "/product/OP");
        String cupssOP = SystemProperties.get("ro.vendor.lge.capp_cupss.op.dir", defValue != null ? defValue : "/product/OP");
        if (cupssOP != null) {
            return cupssOP;
        }
        if (defValue != null) {
            return defValue;
        }
        return "/product/OP";
    }

    public static String getCupssConfigDir() {
        return PATH_CONFIG_LEGACY;
    }
}

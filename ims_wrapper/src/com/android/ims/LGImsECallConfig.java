package com.android.ims;

import android.os.Parcel;
import android.os.Parcelable;

public class LGImsECallConfig implements Parcelable {
    public static final Parcelable.Creator<LGImsECallConfig> CREATOR = new LGImsECallConfigCreator();
    public static final int IPCAN_ALL = 3;
    public static final int IPCAN_LTE = 1;
    public static final int IPCAN_NONE = 0;
    public static final int IPCAN_WIFI = 2;
    private final boolean mControlledByVoLteReg;
    private final boolean mControlledByVoLteSetting;
    private final boolean mNormalCallEndRequired;
    private final int mSupportedIPCAN;

    public LGImsECallConfig(int supportedIPCAN, boolean controlledByVoLteSetting, boolean controlledByVoLteReg, boolean normalCallEndRequired) {
        this.mSupportedIPCAN = supportedIPCAN;
        this.mControlledByVoLteSetting = controlledByVoLteSetting;
        this.mControlledByVoLteReg = controlledByVoLteReg;
        this.mNormalCallEndRequired = normalCallEndRequired;
    }

    public int getIpcanForECall() {
        return this.mSupportedIPCAN;
    }

    public boolean isECallControlledByVoLteReg() {
        return this.mControlledByVoLteReg;
    }

    public boolean isECallControlledByVoLteSetting() {
        return this.mControlledByVoLteSetting;
    }

    public boolean isECallSupportedInLte() {
        return (this.mSupportedIPCAN & 1) != 0;
    }

    public boolean isECallSupportedInWifi() {
        return (this.mSupportedIPCAN & 2) != 0;
    }

    public boolean isImsCallEndRequiredForECall() {
        return this.mNormalCallEndRequired;
    }

    public String toString() {
        StringBuffer sb = new StringBuffer();
        sb.append("{ ImsECallConfig: supportedIPCAN=");
        sb.append(this.mSupportedIPCAN);
        sb.append(", controlledByVoLteSetting=");
        sb.append(this.mControlledByVoLteSetting);
        sb.append(", controlledByVoLteReg=");
        sb.append(this.mControlledByVoLteReg);
        sb.append(", normalCallEndRequired=");
        sb.append(this.mNormalCallEndRequired);
        sb.append(" }");
        return sb.toString();
    }

    public int describeContents() {
        return 0;
    }

    public void writeToParcel(Parcel out, int flags) {
        out.writeInt(this.mSupportedIPCAN);
        out.writeInt(this.mControlledByVoLteSetting ? 1 : 0);
        out.writeInt(this.mControlledByVoLteReg ? 1 : 0);
        out.writeInt(this.mNormalCallEndRequired ? 1 : 0);
    }
    
    public static class LGImsECallConfigCreator implements Parcelable.Creator<LGImsECallConfig> {

        public LGImsECallConfig createFromParcel(Parcel source) {
            int supportedIPCAN = source.readInt();
            int controlledByVoLteSetting = source.readInt();
            int controlledByVoLteReg = source.readInt();
            int normalCallEndRequired = source.readInt();
            boolean z = false;
            boolean z2 = controlledByVoLteSetting != 0;
            boolean z3 = controlledByVoLteReg != 0;
            if (normalCallEndRequired != 0) {
                z = true;
            }
            return new LGImsECallConfig(supportedIPCAN, z2, z3, z);
        }

        public LGImsECallConfig[] newArray(int size) {
            return new LGImsECallConfig[size];
        }
    }
}

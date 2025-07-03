package models;

import com.owlike.genson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

/**
 * This is the model of the asset
 */

@DataType
public final class PublicInformation {

    @Property
    private final String data;

    @Property
    private final boolean status;

    public String getData() {
        return this.data;
    }

    public boolean getStatus() {
        return this.status;
    }

    public PublicInformation(@JsonProperty("data") final String data, @JsonProperty("status") final boolean status) {
        this.data = data;
        this.status = status;
    }
}

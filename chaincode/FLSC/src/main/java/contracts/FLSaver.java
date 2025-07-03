package contracts;

import com.owlike.genson.Genson;
import com.owlike.genson.GensonBuilder;
import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.protos.peer.ChaincodeShim;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIteratorWithMetadata;
import java.util.HashMap;

@Contract(name = "", info = @Info(title = "Save and verify data from IoT sources", description = "", version = "1.0"))
@Default
public final class FLSaver implements ContractInterface {
    private final Genson genson = new GensonBuilder().create();
    private static int pageSize = 2;

@Transaction()
public String pushData(final Context ctx, final String key, final String data) {
    ChaincodeStub stub = ctx.getStub();
    String newKey = key;
    stub.putStringState(newKey, data);
    System.out.println("PUSHING: " + data);

    HashMap<String, String> map = new HashMap<>();
    map.put(newKey, data);
    System.out.println("PUSHING: " + genson.serialize(map));
    return genson.serialize(map);
}


  @Transaction()
public String pullData(final Context ctx, final String id) {
    ChaincodeStub stub = ctx.getStub();
    String selector = "{\"selector\":{\"id\":\"" + id + "\"}}";
    String bookmark = "";
    int fetchedRecordsCount = 0;
    HashMap<String, String> results = new HashMap<>();
    int total = 0;
    long first = System.nanoTime();
    System.out.println("SELECTOR: " + selector);
    QueryResultsIteratorWithMetadata<KeyValue> queryResultWithPagination = stub.getQueryResultWithPagination(selector, pageSize, bookmark);
    for (KeyValue keyValue : queryResultWithPagination) {
        System.out.println("PAGINATION RESULT: " + new String(keyValue.getValue()));
        results.put(keyValue.getKey(), new String(keyValue.getValue()));
    }    

    long l = (System.nanoTime() - first);
    System.out.println("TIME TO query with pagination: " + l);
    System.out.println("queryResultWithPagination.getMetadata().getFetchedRecordsCount() : " + queryResultWithPagination.getMetadata().getFetchedRecordsCount() );

    if (queryResultWithPagination.getMetadata().getFetchedRecordsCount() > 0) {
        do {

            ChaincodeShim.QueryResponseMetadata metadata = queryResultWithPagination.getMetadata();
            fetchedRecordsCount = metadata.getFetchedRecordsCount();
            bookmark = metadata.getBookmark();

            for (KeyValue keyValue : queryResultWithPagination) {
                System.out.println("PAGINATION RESULT: " + new String(keyValue.getValue()));
                results.put(keyValue.getKey(), new String(keyValue.getValue()));
            }

            queryResultWithPagination = stub.getQueryResultWithPagination(selector, pageSize, bookmark);
            total += fetchedRecordsCount;


            l = (System.nanoTime() - first) / 1_000_000_000;
            if (l > 25) { // parar en 25 segundos
                break;
            }
        } while (fetchedRecordsCount > 0);
    }

    long ll = (System.nanoTime() - first);
    System.out.println("TIME TO query with pagination: " + ll);

    if (ll/ 1_000_000_000 > 30) {
        System.err.println("Error: TIMEOUT: more than 30 seconds on client, reset.");
    }

    return genson.serialize(results);
}

}

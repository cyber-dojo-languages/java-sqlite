// The test half of the workload the AOT caches are recorded from. Reading a row
// back is what pulls the driver's statement and result-set classes into the
// cache alongside JUnit's own runner.
//
// It passes, because a JVM writes a cache when it exits of its own accord and a
// green run is the simplest way to be sure of that.
import org.junit.Test;
import static org.junit.Assert.assertEquals;

public class GreeterTest {

    @Test
    public void reads_back_what_it_stored() {
        assertEquals("hello", Greeter.greeting());
    }
}

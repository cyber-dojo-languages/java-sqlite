// Part of the workload the AOT caches are recorded from. It has to exist before
// any learner's kata does, so what the caches hold are the compiler's classes,
// JUnit's and the SQLite driver's rather than any kata's, and they speed up
// whatever a learner writes.
//
// It talks to an in-memory database rather than a file, so that recording the
// caches leaves nothing behind on disk. Going through DriverManager is the point
// of it: that is what loads the driver, and the driver is the slowest thing a
// kata here loads.
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Greeter {

    public static String greeting() {
        try (Connection connection = DriverManager.getConnection("jdbc:sqlite::memory:");
             Statement statement = connection.createStatement()) {
            statement.execute("CREATE TABLE greetings (word text NOT NULL);");
            statement.execute("INSERT INTO greetings VALUES ('hello');");
            ResultSet resultSet = statement.executeQuery("SELECT word FROM greetings;");
            return resultSet.getString("word");
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;

public class Hiker {

    public static void setup() {
        String create_sql = "CREATE TABLE IF NOT EXISTS earth "
            + "(question text NOT NULL,\n"
            + "	answer int\n"
            + ");";
        String delete_sql = "DELETE FROM earth;";
        String insert_sql = "INSERT INTO earth "
            + " VALUES ('6 * 9', 54);";

        try (Connection connection = DriverManager.getConnection(connectionString);
             Statement statement = connection.createStatement()) {
            statement.execute(create_sql);
            statement.execute(delete_sql);
            statement.execute(insert_sql);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public static int answer() {
        String query_sql = "SELECT answer FROM earth WHERE question='6 * 9';";
        try (Connection connection = DriverManager.getConnection(connectionString);
             Statement statement = connection.createStatement()) {
            ResultSet resultSet = statement.executeQuery(query_sql);
            return resultSet.getInt("answer");
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    private static String connectionString =
        "jdbc:sqlite:/sandboxes/shared/change-me.db";
}

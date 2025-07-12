
/* ●患者1のコード（Java + PostgreSQL）*/
import java.sql.*;

public class Cumlative {
     public static void main(String[] args) throws Exception {

          /* 1) データベースへの接続情報 */
          Connection con = null; 
          Statement st = null;
          ResultSet rs = null;

          String url = "jdbc:postgresql://localhost:5432/shop";
          String user = "postgres";
          String password = "test"; 

          String strResult = null;

          /* 2) 変数の初期化 */
          String strOldShop = "";
          String strCurShop = "";
          int intCumlative = 0;   /* 累計 */

          /* 3) JDBCドライバの定義 */
          Class.forName("org.postgresql.Driver");

          /* 4) PostgreSQLへの接続 */
          con = DriverManager.getConnection(url, user, password);
          st = con.createStatement();

          /* 5) SELECT文の実行 */
          rs = st.executeQuery("SELECT * FROM SalesIcecream ORDER BY shop_id, sale_date");


          /* 6) ヘッダの表示 */
          String strHeader = " shop_id | sale_date  | sales_amt | cumlative    " + "\n";
          System.out.print(strHeader);
          
          /* 7) 結果セットを一行づつループ */
          while (rs.next()){

               /* 8) 累計を加算 */
               intCumlative = intCumlative + rs.getInt("sales_amt");
               strCurShop = rs.getString("shop_id");

               /* 9) 店舗が異なる場合は累計をリセット */
               if (strOldShop.equals(strCurShop) == false){
                    intCumlative = rs.getInt("sales_amt");
                    System.out.print("---------+------------+-----------+----------" + "\n");
               }

               /* 10) 結果の画面表示 */
               strResult =  rs.getString("shop_id") + "     |" + rs.getDate("sale_date") + "  |     " 
               + String.format("%6d", rs.getInt("sales_amt")) + "|" + String.format("%10d", intCumlative) + "\n";
               System.out.print(strResult);

               strOldShop = strCurShop;

          }

          /* 11) データベースとの接続を切断 */
          rs.close(); 
          st.close();
          con.close();
     }
}

●ウィンドウ関数による解（再掲）
SELECT shop_id,
       sale_date,
       sales_amt,
       SUM(sales_amt) OVER (PARTITION BY shop_id 
                                ORDER BY sale_date) AS cumlative_amt
  FROM SalesIcecream;

●ループの中で利用されているクエリ
SELECT * FROM SalesIcecream ORDER BY shop_id, sale_date;


●患者2のコード（Java + PostgreSQL）
import java.sql.*;

public class MinSeq {
     public static void main(String[] args) throws Exception {

          /* 1) データベースへの接続情報 */
          Connection con = null; 
          Statement st = null;
          ResultSet rs = null;

          String url = "jdbc:postgresql://localhost:5432/shop";
          String user = "postgres";
          String password = "test"; 

          String strResult = null;

          /* 2) 現在の値と一つ前の値 */
          String strOldCustomer = "";
          String strCurCustomer = "";
          int intPrice = 0;

          int intCurSeq = 0;  
          int intOldSeq = 0;  

          /* 3) JDBCドライバの定義 */
          Class.forName("org.postgresql.Driver");

          /* 4) PostgreSQLへの接続 */
          con = DriverManager.getConnection(url, user, password);
          st = con.createStatement();

          /* 5) SELECT文の実行 */
          rs = st.executeQuery("SELECT * FROM Receipts ORDER BY customer_id, seq, price");


          /* 6) ヘッダの表示 */
          String strHeader = "customer_id| seq | price   " + "\n";
          System.out.print(strHeader);
          System.out.print("-----------+-----+---------" + "\n");


          /* 7) 結果セットを一行づつループ */
          while (rs.next()){

               strCurCustomer = rs.getString("customer_id");
               
               /* 顧客IDが変わったら、最小の連番を出力 */
               if (strOldCustomer.equals(strCurCustomer) == false){

                    /* 8) 各列の更新 */
                    intCurSeq =  rs.getInt("seq");
                    intPrice = rs.getInt("price");

                    /* 9) 結果の画面表示 */
                    strResult =  strCurCustomer + "       |" + String.format("%3d", intCurSeq) + "  |   " 
                         + String.format("%6d", intPrice) + "\n";
                    System.out.print(strResult);


               }

               strOldCustomer = strCurCustomer;

          }

          /* 10) データベースとの接続を切断 */
          rs.close(); 
          st.close();
          con.close();
     }
}

●SQLによる解：ウィンドウ関数（再掲）
SELECT *
  FROM (SELECT customer_id, seq, price,
               FIRST_VALUE(price) OVER (PARTITION BY customer_id 
                                            ORDER BY seq) AS min_price
          FROM Receipts) TMP
 WHERE price = min_price;



●患者3：データベースの更新処理（Java + PostgreSQL）
import java.sql.*;

public class StockTrend {
     public static void main(String[] args) throws Exception {

          /* 1) データベースへの接続情報 */
          Connection con = null; 
          Statement st = null;
          Statement stUpdate = null;
          ResultSet rs = null;

          String url = "jdbc:postgresql://localhost:5432/shop";
          String user = "postgres";
          String password = "test"; 

          String strResult = null;
          String strUpdate = null;

          /* 2) 株価の初期化 */
          String strOldTicker = "";
          String strCurTicker = "";
          int intOldPrice = 0;
          int intCurPrice = 0;
          int intTrend = 0;

          /* 3) JDBCドライバの定義 */
          Class.forName("org.postgresql.Driver");

          /* 4) PostgreSQLへの接続 */
          con = DriverManager.getConnection(url, user, password);
          st = con.createStatement();
          stUpdate = con.createStatement();

          /* 5) SELECT文の実行 */
          rs = st.executeQuery("SELECT * FROM StockHistory ORDER BY ticker_symbol, sale_date");


          /* 6) 結果セットを一行づつループ */
          while (rs.next()){

               /* 7) 現在の企業を取得 */
               strCurTicker = rs.getString("ticker_symbol");

               intCurPrice = rs.getInt("closing_price");


               /* 8) 企業が同じ場合は株価を比較してtrendを計算 */
               if (strOldTicker.equals(strCurTicker)){
                    if (intCurPrice > intOldPrice) {
                         intTrend = 1;
                    } else if (intOldPrice == intCurPrice){
                         intTrend = 0;
                    } else {
                         intTrend = -1;
                    } 
               } else {
                    intTrend = 0;
               }

               /* トランザクション開始 */
               con.setAutoCommit(false);

               /* 9) UPDATE文を実行 */
               strUpdate = "UPDATE StockHistory " + 
                              "SET trend = " + intTrend + " " +
                            "WHERE ticker_symbol = '" + rs.getString("ticker_symbol") + "' " +
                              "AND sale_date = '" + rs.getDate("sale_date") + "'";

               stUpdate.executeUpdate(strUpdate);              

               /* コミット */
               con.commit();

               intOldPrice = intCurPrice;
               strOldTicker = strCurTicker;

          }

          /* 10) データベースとの接続を切断 */
          rs.close(); 
          st.close();
          stUpdate.close();
          con.close();
     }
}

●患者3のコードから実行されるUPDATE文（一回目）
UPDATE StockHistory
   SET trend = 0
 WHERE ticker_symbol = 'A社   ' 
   AND sale_date = '2024-04-01';



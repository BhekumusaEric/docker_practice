package za.co.wethinkcode;

import java.net.ServerSocket;
import java.net.Socket;
import java.io.*;

public class EchoServer {
    public static void main(String[] args) throws Exception {
        System.out.println("Hello. Starting server");

        ServerSocket server = new ServerSocket(9000);
        System.out.println("Listening on port 9000");

        while (true) {
            Socket clientSocket = server.accept();
            BufferedReader in = new BufferedReader(
                    new InputStreamReader(
                            clientSocket.getInputStream()
                    )
            );

            String s;
            while ((s = in.readLine()) != null) {
                System.out.println(s);
            }

            System.err.println("Closing connection.");
            in.close();
            clientSocket.close();
        }
    }
}
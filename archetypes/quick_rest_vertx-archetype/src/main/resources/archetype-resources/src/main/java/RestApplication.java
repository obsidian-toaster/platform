/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 * <p>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package ${package};

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Future;
import io.vertx.core.json.Json;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;
import ${package}.service.Greeting;

import static io.vertx.core.http.HttpHeaders.CONTENT_TYPE;

public class RestApplication extends AbstractVerticle {

  private static final String template = "Hello, %s!";
  private long counter;

  @Override
  public void start(Future done) {
    // Create a router object.
    Router router = Router.router(vertx);

    router.get("/greeting").handler(this::greeting);

    // Create the HTTP server and pass the "accept" method to the request handler.
    vertx
        .createHttpServer()
        .requestHandler(router::accept)
        .listen(
            // Retrieve the port from the configuration,
            // default to 8080.
            config().getInteger("http.port", 8080),
            done.completer());
  }

  private void greeting(RoutingContext rc) {
    String name = rc.request().getParam("name");
    if (name == null) {
      name = "World";
    }
    rc.response()
        .putHeader(CONTENT_TYPE, "application/json; charset=utf-8")
        .end(Json.encode(new Greeting(++counter, String.format(template, name))));
  }
}

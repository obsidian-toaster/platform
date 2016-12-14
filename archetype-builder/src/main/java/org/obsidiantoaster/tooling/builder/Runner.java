/**
 * Copyright 2005-2015 Red Hat, Inc.
 *
 * Red Hat licenses this file to you under the Apache License, version
 * 2.0 (the "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied.  See the License for the specific language governing
 * permissions and limitations under the License.
 */
package org.obsidiantoaster.tooling.builder;

/**
 * Just for debugging purposes. Do not use it
 *
 * @author <a href="mailto:ggastald@redhat.com">George Gastaldi</a>
 */
public class Runner {

	public static void main(String[] args) throws Exception {
		System.setProperty("basedir", "/home/ggastald/workspace/obsidian/platform/archetype-builder");
		System.setProperty("outputdir", "/home/ggastald/workspace/obsidian/platform/archetype-builder/../archetypes");
		System.setProperty("sourcedir", "/home/ggastald/workspace/obsidian/platform/archetype-builder/../quickstart");
		System.setProperty("project.version", "1.0.0-SNAPSHOT");
		Main.main(args);
	}
}

/*
 * Copyright 2016 Red Hat, Inc. and/or its affiliates.
 *
 * Licensed under the Eclipse Public License version 1.0, available at
 * http://www.eclipse.org/legal/epl-v10.html
 */

package io.obsidian.tooling.builder;

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

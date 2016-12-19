/*
 * Copyright 2016 Red Hat, Inc. and/or its affiliates.
 *
 * Licensed under the Eclipse Public License version 1.0, available at
 * http://www.eclipse.org/legal/epl-v10.html
 */

package org.obsidiantoaster.tooling.builder;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.fabric8.utils.Strings;

/**
 *
 * @author <a href="mailto:ggastald@redhat.com">George Gastaldi</a>
 */
public class GenerateCatalog {

	public static Logger LOG = LoggerFactory.getLogger(GenerateCatalog.class);

	public static void main(String[] args) throws Exception {
		String basedir = System.getProperty("basedir");
		if (Strings.isNullOrBlank(basedir)) {
			basedir = ".";
		}

		File bomFile = new File(basedir, System.getProperty("rootPomFile", "../pom.xml"));
		File catalogFile = new File(basedir, "target/classes/archetype-catalog.xml").getCanonicalFile();
		catalogFile.getParentFile().mkdirs();

		String outputPath = System.getProperty("outputdir");
		File outputDir = Strings.isNotBlank(outputPath) ? new File(outputPath) : new File(basedir);

		File archetypesPomFile = new File(basedir, "../archetypes/pom.xml").getCanonicalFile();

		ObsidianCatalogBuilder builder = new ObsidianCatalogBuilder(catalogFile);
		builder.setBomFile(bomFile);
		builder.setArchetypesPomFile(archetypesPomFile);
		builder.configure();

		List<String> dirs = new ArrayList<>();
		try {

			for (File file : outputDir.listFiles()) {
				// if the archetype was built...
				File pom = new File(file, "pom.xml");
				File target = new File(file, "target");
				if (pom.exists() && target.exists()) {
					builder.addArchetypeMetaData(pom, file.getName());
				}
			}

		} finally {
			LOG.debug("Completed the generation. Closing!");
			builder.close();
		}

		StringBuffer sb = new StringBuffer();
		for (String dir : dirs) {
			sb.append("\n\t<module>" + dir + "</module>");
		}
		System.out.println("Done creating archetypes:\n" + sb + "\n");

		Set<String> missingArtifactIds = builder.getMissingArtifactIds();
		if (missingArtifactIds.size() > 0) {
			System.out.println();
			System.out.println();
			System.out.println(
					"WARNING the following archetypes were not added to the archetypes catalog: " + missingArtifactIds);
			System.out.println();
			System.out.println("To add them please type the following commands into the terminal:");
			System.out.println();
			for (String missingArtifactId : missingArtifactIds) {
				System.out.println("git add archetypes/" + missingArtifactId);
			}
			System.out.println();
			System.out.println("Then add the following XML into the archetypes/pom.xml file in the <modules> element:");
			System.out.println();
			for (String missingArtifactId : missingArtifactIds) {
				System.out.println("    <module>" + missingArtifactId + "</module>");
			}
			System.out.println();
			System.out.println("Then git commit and submit a PR please!");
			System.out.println();
		}
	}
}

package io.obsidian.tooling.builder;

import io.obsidian.tooling.ArchetypeUtils;

/**
 * A base support class for Builders.
 */
public class AbstractBuilder {

    protected ArchetypeUtils archetypeUtils = new ArchetypeUtils();
    protected int indentSize = 2;
    protected String indent = "  ";

    public void setIndentSize(int indentSize) {
        this.indentSize = Math.min(indentSize <= 0 ? 0 : indentSize, 8);
        indent = "";
        for (int c = 0; c < this.indentSize; c++) {
            indent += " ";
        }
    }


}


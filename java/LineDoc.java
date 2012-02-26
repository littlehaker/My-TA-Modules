// Copyright 2007-2012 Mitchell mitchell<att>caladbolg.net. See LICENSE.

import com.sun.javadoc.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;

/**
 * Adeptsense doclet for JavaDoc.
 * This module is used by JavaDoc to create an adeptsense api file for Java
 * code.
 *
 * Compiling:
 *   WIN32: javac -cp "%JAVA_HOME%\lib\tools.jar" LineDoc.java
 *   Linux: javac -cp /usr/lib/jvm/java-6-openjdk/lib/tools.jar LineDoc.java
 *
 * Running:
 *   javadoc -doclet Linedoc -docletpath /path/to/LineDoc ... > api
 *
 * @author foral
 */
public class LineDoc {
	/**
	 * Javadoc for start function.
	 * Function description.
	 * {@link foo}
	 * @param root The RootDoc object.
	 * @return boolean
	 */
	public static boolean start(RootDoc root) {
		try {
			ClassDoc[] classes = root.classes();
			for (int i = 0; i < classes.length; i++) {
				String class_name = classes[i].name();

				// Constructors.
				ConstructorDoc[] constructors = classes[i].constructors();
				for (int j = 0; j < constructors.length; j++)
					write_method_doc("", constructors[j]);

				// Methods
				MethodDoc[] methods = classes[i].methods();
				for (int j = 0; j < methods.length; j++)
					write_method_doc(class_name, methods[j]);

				// Fields
				FieldDoc[] fields = classes[i].fields();
				for (int j = 0; j < fields.length; j++) {
					StringBuilder doc = new StringBuilder();
					append_name(classes[i].name(), fields[j].name(), doc);
					append_type(fields[j].type(), doc);
					append_modifiers(fields[j].modifiers(), doc);
					append_comment_text(fields[j].commentText(), doc);
					append_tags(fields[j].tags(), doc);
					write_api(fields[j].name(), doc);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return true;
	}

	static void write_method_doc(String class_name, ExecutableMemberDoc method)
	throws Exception {
		StringBuilder doc = new StringBuilder();
		append_name(class_name, method.name(), doc);
		append_params(method.parameters(), doc);
		if (method instanceof MethodDoc)
			append_type(((MethodDoc) method).returnType(), doc);
		else
			doc.append("\n");
		append_modifiers(method.modifiers(), doc);
		append_comment_text(method.commentText(), doc);
		append_tags(method.tags(), doc);
		write_api(method.name(), doc);
	}

	static void append_name(String class_name, String name, StringBuilder doc) {
		if (class_name.length() > 0) class_name += ".";
		doc.append(class_name + name);
	}

	static void append_params(Parameter[] params, StringBuilder doc) {
		doc.append("(");
		for (int k = 0; k < params.length; k++)
			doc.append(params[k].typeName() + " " + params[k].name() + ", ");
		if (params.length > 0) doc.delete(doc.length() - 2, doc.length());
		doc.append(")");
	}

	static void append_type(Type type, StringBuilder doc) {
		doc.append(" [" + type.typeName() + type.dimension() + "]\n");
	}

	static void append_modifiers(String modifiers, StringBuilder doc) {
		doc.append("Modifiers: " + modifiers + "\n");
	}

	static void append_comment_text(String comment_text, StringBuilder doc) {
		doc.append(comment_text.replaceAll("\\n", "").
							 replaceAll("\\\\n", "\\\\n").
							 replaceAll("\\{@\\w+\\s+([^}]+)\\}", "`$1`").
							 replaceAll("<[^>\n]+>", ""));
		doc.append("\n");
	}

	static void append_tags(Tag[] tags, StringBuilder doc) {
		for (int k = 0; k < tags.length; k++) {
			doc.append(tags[k].name());
			doc.append(" ");
			doc.append(tags[k].text().replaceAll("\\n", "\\\\n"));
			doc.append("\n");
		}
	}

	static void write_api(String name, StringBuilder doc) throws Exception {
		// Execute fmt with doc as stdin.
		Process p = Runtime.getRuntime().exec("fmt -s -w 80");
		OutputStream stdin = p.getOutputStream();
		stdin.write(doc.toString().getBytes());
		stdin.close();

		// Read the stdout from fmt.
		doc.delete(0, doc.length());
		doc.append(name);
		doc.append(" ");
		String line;
		BufferedReader stdout =
			new BufferedReader(new InputStreamReader(p.getInputStream()));
		while ((line = stdout.readLine()) != null) {
			doc.append(line);
			doc.append("\\n");
		}
		stdout.close();
		p.waitFor();

		// method class.method(arg1, arg2, ...)\ncomment text\n@tags ...
		System.out.println(doc.toString());
	}
}

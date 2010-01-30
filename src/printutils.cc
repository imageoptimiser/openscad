#include "printutils.h"
#include "MainWindow.h"

QList<QString> print_messages_stack;

void print_messages_push()
{
	print_messages_stack.append(QString());
}

void print_messages_pop()
{
	QString msg = print_messages_stack.last();
	print_messages_stack.removeLast();
	if (print_messages_stack.size() > 0 && !msg.isNull()) {
		if (!print_messages_stack.last().isEmpty())
			print_messages_stack.last() += "\n";
		print_messages_stack.last() += msg;
	}
}

void PRINT(const QString &msg)
{
	if (msg.isNull())
		return;
	if (print_messages_stack.size() > 0) {
		if (!print_messages_stack.last().isEmpty())
			print_messages_stack.last() += "\n";
		print_messages_stack.last() += msg;
	}
	PRINT_NOCACHE(msg);
}

void PRINT_NOCACHE(const QString &msg)
{
	if (msg.isNull())
		return;
	if (MainWindow::current_win.isNull()) {
		fprintf(stderr, "%s\n", msg.toAscii().data());
	} else {
		MainWindow::current_win->console->append(msg);
	}
}

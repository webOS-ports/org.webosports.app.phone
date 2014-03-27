/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QQmlEngine>
#include <QQmlContext>
#include <QQuickItem>

#include <glib.h>
#include <webos_application.h>

#include "phoneapplication.h"

struct webos_application_event_handlers event_handlers = {
    .activate = NULL,
    .deactivate = NULL,
    .suspend = NULL,
    .relaunch = PhoneApplication::onRelaunch,
    .lowmemory = NULL
};

PhoneApplication::PhoneApplication(int& argc, char **argv) :
    QGuiApplication(argc, argv)
{
    webos_application_init("org.webosports.app.phone", &event_handlers, this);
    webos_application_attach(g_main_loop_new(g_main_context_default(), TRUE));

    setApplicationName("PhoneApp");
}

PhoneApplication::~PhoneApplication()
{
}

bool PhoneApplication::setup(const QString& path)
{
    if (path.isEmpty()) {
        qWarning() << "Invalid app path:" << path;
        return false;
    }

    mEngine.rootContext()->setContextProperty("application", this);

    QQmlComponent appComponent(&mEngine, QUrl(path));
    if (appComponent.isError()) {
        qWarning() << "Errors while loading app from" << path;
        qWarning() << appComponent.errors();
        return false;
    }

    QObject *app = appComponent.beginCreate(mEngine.rootContext());
    if (!app) {
        qWarning() << "Error creating app from" << path;
        qWarning() << appComponent.errors();
        return false;
    }

    appComponent.completeCreate();

    return true;
}

void PhoneApplication::onRelaunch(const char *parameters, void *user_data)
{
    PhoneApplication *app = static_cast<PhoneApplication*>(user_data);
    app->relaunch(parameters);
}

void PhoneApplication::relaunch(const char *parameters)
{
    emit relaunched(QString(parameters));
}

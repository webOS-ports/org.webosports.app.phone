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

#ifndef PHONEAPPLICATION_H
#define PHONEAPPLICATION_H

#include <QObject>
#include <QQmlEngine>
#include <QGuiApplication>

class PhoneApplication : public QGuiApplication
{
    Q_OBJECT
public:
    explicit PhoneApplication(int& argc, char **argv);
    virtual ~PhoneApplication();

    bool setup(const QString& path);

private:
    QQmlEngine mEngine;
};

#endif // PHONEAPPLICATION_H

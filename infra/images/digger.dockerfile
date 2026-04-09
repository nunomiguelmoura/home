FROM mcr.microsoft.com/dotnet/sdk:10.0

WORKDIR /tmp

COPY ./ ./

RUN dotnet publish /tmp/Digger/Digger.csproj -o /digger

RUN rm -rf /tmp

ENTRYPOINT ["dotnet", "/digger/Digger.dll"]

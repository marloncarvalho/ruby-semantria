# encoding:utf-8

require 'semantria'

# Callback passado para a API do Semantria.
# Apenas imprime o status.
#
# Author Marlon Silva Carvalho
class SessionCallbackHandler < CallbackHandler

  def onRequest(sender, args)
    puts '####### Realizando Requisição ao servidor.'
  end

  def onResponse(sender, args)
    puts '####### Resposta do servidor recebida.'
  end

  def onError(sender, args)
    print '###### Ocorreu um erro: ', args, "\n"
  end

  def onDocsAutoResponse(sender, args)
  end

  def onCollsAutoResponse(sender, args)
  end

end

# Exemplo de como usar a API do Semantria para analisar
# um conjunto de documentos.
#
# Author Marlon Silva Carvalho
class Rubytria

  # Processar um arquivo considerando cada linha dele como um documento separado.
  # Enfileirar esses documentos na API do Semantria e aguardar pelo retorno até que todos tenham sido processados.
  #
  def queue(f)
    configure
    get_documents_from_file f

    @documents.each do |text|

      # Precisamos atribuir um ID para cada documento.
      # Vamos gerar esse ID de forma aleatória.
      #
      doc = {'id' => rand(10 ** 10).to_s.rjust(10, '0'), 'text' => text}
      status = @session.queueDocument(doc)
      if status == 202
        print 'Documento ', doc['id'], ' enfileirado com sucesso.', "\r\n"
      end
    end

    @results = []

    while @results.length < @documents.length
      print 'Aguarde 10 segundos, estamos esperando o processamento dos documentos no Semantria...', "\r\n"
      sleep(10)
      status = @session.getProcessedDocuments()
      status.is_a? Array and status.each do |object|
        @results.push(object)
      end
      print status.length, '  documentos foram recebidos com sucesso pelo Semantria.', "\r\n"
    end

    @results
  end

  # Imprimir no console os dados de um documento.
  #
  def print_doc(data)
    print "Documento #{data['id']} Status: #{data['status']} Nível do Sentimento: #{data['sentiment_score']} \r\n"
    print 'Temas encontrados:', "\r\n"
    data['themes'].nil? or data['themes'].each do |theme|
      print '  ', theme['title'], ' (sentimento: ', theme['sentiment_score'], ')', "\r\n"
    end
    print 'Entidades encontradas:', "\r\n"
    data['entities'].nil? or data['entities'].each do |entity|
      print '  ', entity['title'], ' : ', entity['entity_type'], ' (sentimento: ', entity['sentiment_score'], ')', "\r\n"
    end

    print 'Categorias:', "\r\n"
    data['auto_categories'].nil? or data['auto_categories'].each do |entity|
      print '  ', entity['title'], ' : ', entity['type'], ' (Força: ', entity['strength_score'], ')', "\r\n"

      print 'Subcategorias:', "\r\n"
      data['categories'].nil? or data['categories'].each do |c|
        print '  ', c['title'], ' : ', entity['type'], ' (Força: ', entity['strength_score'], ')', "\r\n"
      end
    end

    print "\r\n"
  end

  # Obter a lista de documentos já enviados e processados no Semantria.
  #
  def get_processed_documents
    @session.getProcessedDocuments
  end

  # Obter os resultados de um documento.
  def get_document(id)
    @session.getDocument id
  end

  private

  # Lê linha a linha o arquivo documentos.txt e considera cada linha
  # como um documento.
  #
  def get_documents_from_file(f)
    @documents = []

    print("Lendo do arquivo documentos.txt...\n")
    f = File.open(f).read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      @documents.push(line)
    end

    if @documents.size < 1
      print("O arquivo #{f} não existe.\n")
      exit(1)
    end

    @documents
  end

  # Vamos inicializar, fazendo a conexão com API do Semantria.
  #
  def configure
    @session = Session.new('', '', 'TestApp', true)
    @callback = SessionCallbackHandler.new()
    @session.setCallbackHandler(@callback)
  end

end

semantria = Rubytria.new
semantria.queue('documentos.txt').each do |data|
  semantria.print_doc data
end
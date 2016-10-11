(ns oredoc.core
  (:gen-class)
  (:require
    [clojure.java.io   :as io]
    [clojure.string    :as str]
    [clojure.tools.cli :refer [parse-opts]]
    [clojurewerkz.elastisch.rest          :as esr]
    [clojurewerkz.elastisch.rest.document :as esd]
    [clojurewerkz.elastisch.rest.index    :as esi]))

(def ^:private my-mappings
  {"document"
   {:properties
    {:path     {:type "string" :index    "not_analyzed"}
     :body     {:type "string" :analyzer "ja" :term_vector "with_positions_offsets"}
     :modified {:type "date"}}}})

(def ^:dynamic *hostname* nil)
(def ^:dynamic *port* nil)
(def ^:dynamic *silent* false)
(def ^:const INDEX_NAME "oredoc")
(def ^:const TYPE_NAME  "doc")

(defn debug
  [& args]
  (when-not *silent*
    (println (apply format args))))

(defn files
  [dir]
  (->> dir
       io/file
       file-seq
       (remove #(.isDirectory %))
       (remove #(re-seq #"\.git" (.getAbsolutePath %)))))

(defn slurp-and-add-line-nums
  [file]
  (let [lines (str/split-lines (slurp file))]
    (->> lines
         (map (fn [n s]
                (if-not (str/blank? (str/trim s))
                  (str "L" n ": " s)))
              (range 1 (count lines)))
         (remove nil?)
         (str/join "\n"))))

(defn file->document
  [file]
  (let [filename (.getName file)
        path     (.getAbsolutePath file)
        modified (.lastModified file)
        body     (str filename "\n" (slurp-and-add-line-nums file))]
    {:path     path
     :body     body
     :modified modified}))

(defn connect
  []
  (esr/connect (format "http://%s:%d" *hostname* *port*)))

(defn- create-index
  [conn]
  (when-not (esi/exists? conn INDEX_NAME)
    (esi/create conn INDEX_NAME :mappings my-mappings)))

(defn- delete-index
  [conn]
  (when (esi/exists? conn INDEX_NAME)
    (esi/delete conn INDEX_NAME)))

(defn run
  [conn & {:keys [directory flush?] :or {flush? false}}]
  (doseq [f (-> directory io/file files)]
    (debug "* %s" (.getAbsolutePath f))
    (esd/create conn INDEX_NAME TYPE_NAME (file->document f)))
  (when flush?
    (debug "Flushing")
    (esi/flush conn)))

(defn create-docs
  [args]
  (let [conn (connect)]
    (debug "Deleting index")
    (delete-index conn)
    (debug "Creating index")
    (create-index conn)
    (debug "Start to create documents")
    (run conn :directory (first args))
    (debug "Finished")))

(defn update-docs
  [args]
  )

(defn help
  [summary]
  (println "Usage:")
  (println "  java -jar oredoc.jar create /path/to/docs")
  (println "  java -jar oredoc.jar -hlocalhost -p9200 create /path/to/docs")
  (println "Options:")
  (println summary))

(def ^:private cli-options
  [["-h" "--host HOSTNAME" "Elasticsearch host name"
    :default "localhost"]
   ["-p" "--port PORT"     "Elasticsearch port number"
    :default 9200 :parse-fn #(Integer/parseInt %)]
   [nil  "--help"]])

(defn -main
  [& args]
  (let [{:keys [options arguments summary errors]} (parse-opts args cli-options)]
    (when errors
      (doseq [e errors] (println e))
      (System/exit 1))
    (when (or (:help options)
              (< (count arguments) 2))
      (help summary)
      (System/exit 1))

    (binding [*hostname* (:host options)
              *port*     (:port options)]
      (case (first arguments)
        "create" (create-docs (rest arguments))
        "update" (update-docs (rest arguments))
        (help summary)))
    (System/exit 0)))
